require 'test/helpers'
require 'thin_models/struct/typed'

describe "ThinModels::Struct::Typed" do
  class TestTypedClass < ThinModels::Struct::Typed
    register_type do
      property :foo, :integer
      property :bar, :tuple, :integer, :boolean
      property :baz, :boolean
    end
  end

  it 'should shallowly type-check non-lazy properties on construction' do
    assert TestTypedClass.new(:foo => 123)
    assert_raises(TypeError) {TestTypedClass.new(:foo => "abc")}

    assert TestTypedClass.new(:foo => 123, :bar => [123, false])
    assert TestTypedClass.new(:foo => 123, :bar => ["only","shallow"])

    assert_raises(TypeError) {TestTypedClass.new(:foo => 123, :bar => "abc")}
  end

  it "should shallowly type-check properties on attribute assignment" do
    instance = TestTypedClass.new
    instance.foo = 123
    instance.bar = [123, false]
    instance.bar = ["only", "shallow"]
    instance.baz = true
    assert_raises(TypeError) {instance.foo = "not an int"}
    assert_raises(TypeError) {instance.bar = "not a tuple"}
    assert_raises(TypeError) {instance.baz = "not a bool"}
  end

  class TestTypedClassWithIdentity < ThinModels::Struct::Typed
    register_type do
      property :id, :integer
      property :foo, :integer
      property :bar, :tuple, :integer, :boolean
      property :baz, :boolean
    end
    identity_attribute :id
  end

  describe "in combo with Struct::IdentityMethods" do
    it "should work" do
      assert_equal TestTypedClassWithIdentity.new(:id => 123), TestTypedClassWithIdentity.new(:id => 123)
      assert TestTypedClassWithIdentity.new(:id => 123).type_check_property(:id)
      assert_raises(TypeError) {TestTypedClassWithIdentity.new.id = "not an int"}
    end
  end

end
