require 'test/helpers'
require 'thin_models/struct/identity'

describe "ThinModels::Struct::IdentityMethods" do
  def setup
    @klass = ThinModels::StructWithIdentity(:foo, :bar)
  end

  it 'should allow id to be supplied on creation and fetched via an attribute reader or struct[:id]' do
    struct = @klass.new(:id => 123)
    assert_equal 123, struct.id
    assert_equal 123, struct[:id]
  end

  it "should use id for ==/eql?/hash" do
    a = @klass.new(:id => 1, :bar => 2)
    b = @klass.new(:id => 1, :bar => 3)
    assert_equal a, b
    assert_equal a, a.dup
    assert_not_same a, a.dup

    # tests .hash/.eql?
    assert({a => true}[a])
    assert({a => true}[b])
    assert({a => true}[a.dup])
  end

  it "should not equate identity-free instances unless they are the same instance" do
    a = @klass.new(:foo => 2)
    b = @klass.new(:foo => 2)
    assert_equal a, a
    assert_not_equal a, b
    assert_not_equal a, a.dup
  end

  it "should let you use an identity_attribute named something other than :id, but providing id and id= aliases for it" do
    @klass = Class.new(ThinModels::Struct) do
      identity_attribute :foo
    end
    assert_equal @klass.new(:foo => 123), @klass.new(:foo => 123)
    assert_equal 123, @klass.new(:foo => 123).id
    i = @klass.new; i.id = 123
    assert_equal(123, i.id)
    assert_equal(123, i.foo)
  end
end
