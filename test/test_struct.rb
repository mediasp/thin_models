require 'test/helpers'
require 'thin_models/struct'

describe "ThinModels::Struct" do
  def setup
    @klass = ThinModels::Struct(:foo, :bar)
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

  it "should raise PartialDataError for an attribute method, if an attribute's value is not loaded and can't be lazily loaded, rather than silently return nil" do
    assert_raise(ThinModels::PartialDataError) {@klass.new.foo}
  end

  it "should raise PartialDataError for a call to fetch, if an attribute's value is not loaded and can't be lazily loaded, rather than silently return nil" do
    assert_raise(ThinModels::PartialDataError) {@klass.new.fetch(:foo)}
  end

  it "should return nil for a call to [], if an attribute's value is not loaded and can't be lazily loaded" do
    assert_nil @klass.new[:foo]
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

  it "should merge with another ThinModels::Struct, merging in only loaded attributes" do
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
      assert_raise(ThinModels::PartialDataError) {instance.foo}
    end
  end

  describe "#inspect" do
    def setup
      @klass = ThinModels::Struct(:foo, :bar)
      class << @klass; def to_s; 'Foo'; end; end
    end

    it "should include a trailing, ... when there are unevaluated lazy values" do
      instance = @klass.new(:foo => 'present') {|model,property| "lazy"}
      assert_equal "#<Foo foo=\"present\", ...>", instance.inspect
    end

    it "should not overflow the stack when inspecting objects with cycles in their reference graph" do
      instance = @klass.new
      instance.foo = [instance]
      assert_equal "#<Foo foo=[#<Foo ...>]>", instance.inspect
      assert_equal "[#<Foo foo=[...]>]", instance.foo.inspect
    end
  end
end
