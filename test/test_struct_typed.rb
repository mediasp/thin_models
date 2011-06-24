require 'test/helpers'
require 'thin_models/struct/typed'

describe "ThinModels::Struct::Typed" do
  def setup
    @klass = Class.new(ThinModels::Struct::Typed) do
      register_type do
        property :foo, :integer
        property :bar, :tuple, :integer, :boolean
        property :baz, :boolean
      end
    end
  end

  it 'should shallowly type-check non-lazy properties on construction' do
    assert @klass.new(:foo => 123)
    assert_raises(TypeError) {@klass.new(:foo => "abc")}

    assert @klass.new(:foo => 123, :bar => [123, false])
    assert @klass.new(:foo => 123, :bar => ["only","shallow"])

    assert_raises(TypeError) {@klass.new(:foo => 123, :bar => "abc")}
  end

  it "should shallowly type-check properties on attribute assignment" do
    instance = @klass.new
    instance.foo = 123
    instance.bar = [123, false]
    instance.bar = ["only", "shallow"]
    instance.baz = true
    assert_raises(TypeError) {instance.foo = "not an int"}
    assert_raises(TypeError) {instance.bar = "not a tuple"}
    assert_raises(TypeError) {instance.baz = "not a bool"}
  end
end
