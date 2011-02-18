require 'test/helpers'
require 'lazy_data/array'

describe_shared "LazyData::Array" do
  def make_new
    LazyData::Array.new
  end

  def make_new_yielding(*items)
    a = make_new
    # stubbing with Mocha's multiple_yields fails under JRuby in some weird interaction
    # with JRuby's Enumerable that I couldn't quite pin down. So doing it this way for now:
    def a.each(&b); @_items.each(&b); end
    a.instance_variable_set(:@_items, items)
    a
  end

  it "should implement Enumerable" do
    assert_kind_of Enumerable, make_new()
  end

  it "should quack like an Array for length/size/count" do
    @a = make_new_yielding(1,2,3)
    assert_equal 3, @a.length
    assert_equal 3, @a.size
    assert_equal 3, @a.count
    assert_equal 1, @a.count {|x| x == 2}
  end

  it "should quack like an Array for #[] / #slice" do
    @a = make_new_yielding('a','b','c')
    assert_equal 'a', @a[0]
    assert_equal ['a','b'], @a[0..1]
    assert_equal ['a','b'], @a[0...2]
    assert_equal ['a','b'], @a[0...2]
    assert_equal ['b','c'], @a[1,2]
    assert_equal ['b','c'], @a[1,3]
    assert_equal ['c'], @a[2,3]
    assert_equal [], @a[3,3]
    assert_nil @a[4,3]
    assert_nil @a[4,0]
  end

  it "should quack like an Array for #to_a and destructuring assignment" do
    @a = make_new_yielding('a','b','c')
    assert_equal ['a','b','c'], @a.to_a
    head, *tail = @a
    assert_equal 'a', head
    assert_equal ['b','c'], tail
  end

  describe "with #slice_from_start_and_length overridden", self do
    it "should not call #each, only the custom #slice_from_start_and_length, when calling #[] / #slice" do
      @a = make_new_yielding('a','b','c')
      @a.expects(:slice_from_start_and_length).with(0,2).at_least_once.returns(['a','b'])
      @a.expects(:each).never
      assert_equal ['a','b'], @a[0,2]
      assert_equal ['a','b'], @a[0..1]
      assert_equal ['a','b'], @a[0...2]

      @a.expects(:slice_from_start_and_length).with(1,1).at_least_once.returns(['b'])
      assert_equal 'b', @a[1]
    end
  end

  describe "#map", self do
    it "should return a mapped Enumerable" do
      a = make_new_yielding(1,2,3)
      assert_equal([2,3,4], a.map {|x| x+1}.to_a)
    end

    it "should work lazily" do
      a = make_new
      a.expects(:each).never
      a.map {|x| x+1}
      b = make_new
      b.expects(:each).once.multiple_yields(1,2,3)
      mapped = b.map {|x| x+1}
      mapped.each {}
    end

    it "should let you map to a memoized Array::Lazy with memoized = true" do
      b = make_new
      b.expects(:each).once.multiple_yields(1,2,3)
      mapped = b.map(true) {|x| x+1}
      mapped.each {}
      mapped.each {}
      mapped.each {}
    end
  end
end

describe "LazyData::Array" do
  behaves_like "LazyData::Array"

  describe "with #length overridden", self do
    it "should not call #each, only the custom #length, when asking for length, count or size" do
      @a = make_new_yielding('a','b','c')
      @a.stubs(:length).returns(3)
      @a.expects(:each).never
      assert_equal 3, @a.size
      assert_equal 3, @a.count
      assert_equal 3, @a.length
    end
  end
end

describe_shared "LazyData::Array::MemoizedLength" do
  behaves_like "LazyData::Array"

  def make_new_yielding(*items)
    a = make_new
    a.stubs(:_each).multiple_yields(*items)
    a
  end

  describe "with #_length overridden", self do
    it "should not call #each, only the custom #_length, when asking for length, count or size, with #_length called only once even with multiple calls to #length" do
      @a = make_new_yielding('a','b','c')
      @a.stubs(:_length).once.returns(3)
      @a.expects(:each).never
      @a.expects(:_each).never
      assert_equal 3, @a.size
      assert_equal 3, @a.count
      assert_equal 3, @a.length
      assert_equal 3, @a.length
    end
  end

  it "should remember the length after one iteration with #each, not needing to call #_length in order to return the length again" do
    @a = make_new_yielding('a','b','c')
    @a.expects(:_length).never
    @a.each { }
    assert_equal 3, @a.length
    assert_equal 3, @a.size
    assert_equal 3, @a.count
  end
end

describe "LazyData::Array::MemoizedLength" do
  behaves_like "LazyData::Array::MemoizedLength"

  def make_new
    LazyData::Array::MemoizedLength.new
  end
end

describe "LazyData::Array::Memoized" do
  behaves_like "LazyData::Array::MemoizedLength"

  def make_new
    LazyData::Array::Memoized.new
  end

  it "should remember the elements yielded by the first call to each, never calling _each a second time" do
    @a = make_new
    @a.expects(:_each).once.multiple_yields(1,2,3)
    result=[]; @a.each {|x| result << x}
    assert_equal [1,2,3], result
    result=[]; @a.each {|x| result << x}
    assert_equal [1,2,3], result
  end
end
