require 'lazy-data/struct'

describe "LazyData::Struct" do
  def setup
    @klass = LazyData::Struct(:foo, :bar)
  end

  describe "with an identity attribute" do
    def setup
      @klass = LazyData::StructWithIdentity(:foo, :bar)
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
  end

  it "should have getter/setter methods for each attribute, via method calls and via [] / []=" do
    instance = @klass.new(:foo => 'hi')

    assert_equal "hi", instance.foo
    assert_equal "hi", instance[:foo]
    instance.bar = 'byez'
    assert_equal 'byez', instance[:bar]
    instance[:bar] = 'bye'
    assert_equal 'bye', instance.bar
  end

  it "should raise PartialDataError if an attribute's value is not loaded and can't be lazily loaded, rather than silently return nil" do
    assert_raise(LazyData::PartialDataError) {@klass.new.foo}
    assert_raise(LazyData::PartialDataError) {@klass.new[:foo]}
  end

  it "should dup and clone safely" do
    instance = @klass.new(:foo => 123)
    assert_not_same instance, instance.dup
    instance.dup.foo = 345
    assert_not_equal 345, instance.foo
    assert_not_same instance, instance.clone
    instance.clone.foo = 678
    assert_not_equal 678, instance.foo
  end

  it "should freeze safely" do
    instance = @klass.new(:foo => 123)
    instance.freeze
    assert_raise(TypeError) {instance.foo = 234}
  end

  it "should not expose a mutable hash capable of changing its internals" do
    instance = @klass.new(:foo => 123)
    instance.to_hash[:foo] = 345
    assert_not_equal 345, instance.foo
  end

  it "should merge with a Hash" do
    instance = @klass.new(:foo => 123, :bar => 789)
    new_instance = instance.merge(:bar => 456)
    assert_not_equal 456, instance.bar
    assert_equal 456, new_instance.bar
    assert_equal 123, new_instance.foo
  end

  it "should merge with another LazyData::Struct, merging in only loaded attributes" do
    instance = @klass.new(:foo => 123, :bar => 789)
    new_instance = instance.merge(@klass.new(:bar => 456))
    assert_not_equal 456, instance.bar
    assert_equal 456, new_instance.bar
    assert_equal 123, new_instance.foo
  end

  it "shouldn't let you fetch or set non-existent attributes, via [], []= or the constructor" do
    assert_raise(NameError) {@klass.new(:wtf => 123)}
    assert_raise(NameError) {@klass.new[:wtf] = 123}
    assert_raise(NameError) {@klass.new[:wtf]}
  end

  it "should know its attributes" do
    assert_equal Set.new([:foo, :bar]), @klass.attributes
    assert_equal Set.new([:foo, :bar]), @klass.new.attributes
  end

  it "should know if an attribute_loaded? or not" do
    instance = @klass.new(:foo => 123)
    assert instance.attribute_loaded?(:foo)
    assert !instance.attribute_loaded?(:bar)
  end

  describe "when a lazy_values block supplied", self do
    it "should load and subsequently memoize a value lazily by passing the instance and the attribute name to a lazy_values block where supplied" do
      # how do you set expectations in mocha about calls to something you're passing in as a block argument?
      times_called = 0
      instance = @klass.new do |object, attribute|
        assert_same object, instance
        times_called += 1
        if attribute == :foo
          flunk "lazy loader called twice for foo" if times_called > 1
          123
        else
          flunk "unexpected call to lazy loader block"
        end
      end
      assert !instance.attribute_loaded?(:foo)
      assert_equal 123, instance.foo
      assert instance.attribute_loaded?(:foo)
      assert_equal 123, instance.foo
    end

    it "should not call the lazy loader if a value already eagerly passed in for a given property" do
      instance = @klass.new(:foo => 123) do |attribute|
        flunk "unexpected call to lazy loader block"
      end
      assert_equal 123, instance.foo
    end

    it "should stop any further lazy loading and forget about its lazy_values proc on remove_lazy_values" do
      instance = @klass.new do |attribute|
        flunk "unexpected call to lazy loader block"
      end
      assert instance.has_lazy_values?
      instance.remove_lazy_values
      assert !instance.has_lazy_values?
      assert_raise(LazyData::PartialDataError) {instance.foo}
    end

    it "should stop any further lazy loading and forget about its lazy_values once you modify the object, since it only really makes sense to me for an immutable object to be lazily loaded, potential for state bugs otherwise" do
      instance = @klass.new do |attribute|
        flunk "unexpected call to lazy loader block"
      end
      assert instance.has_lazy_values?
      instance.foo = 123
      assert !instance.has_lazy_values?
      assert_equal 123, instance.foo

      instance = @klass.new do |attribute|
        flunk "unexpected call to lazy loader block"
      end
      assert instance.has_lazy_values?
      instance[:foo] = 123
      assert !instance.has_lazy_values?
      assert_equal 123, instance.foo

      instance = @klass.new do |attribute|
        flunk "unexpected call to lazy loader block"
      end
      assert instance.has_lazy_values?
      instance.merge!(:foo => 123)
      assert !instance.has_lazy_values?
      assert_equal 123, instance.foo
    end

  end

end