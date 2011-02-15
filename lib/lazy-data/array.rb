module LazyData
  # Exposes Enumerable and a subset of the interface of Array, but is lazily evaluated.
  #
  # The default constructor allows you to pass in an underlying Enumerable whose .each method will be
  # used; or you can ignore this and override #each and #initialize yourself.
  #
  # You should also consider overriding #length if you have
  # an optimised mechanism for evaluating it without doing a full iteration via #each, and
  # overriding #slice_from_start_and_length if you have an optimised mechanism for iterating over a slice/sub-range of
  # the array. This will be used to supply optimised versions of #[] / #slice
  #
  # Deliberately doesn't expose any mutation methods - is not intended to be a mutable data structure.
  class Array
    include Enumerable

    def initialize(enumerable=nil)
      @enumerable = enumerable
    end

    def each(&b)
      @enumerable.each(&b)
    end

    def inspect
      "[LazyData::Array:...]"
    end

    # We recommend overriding this #length implementation (which is based on #each) with an efficient
    # implementation. #size will use your #length, and #count uses #size where available, hence will
    # use it too.
    def length
      length = 0; each {length += 1}; length
    end

    def size; length; end

    # enables splat syntax: a, *b = lazy_array; foo(*lazy_array) etc.
    alias :to_ary :to_a

    def to_json(*p)
      to_a.to_json(*p)
    end

    # We recommend overriding this inefficient implementation (which uses #each to traverse from
    # the start until it reaches the desired range) with an efficient implementation.
    #
    # Returns an array for the requested slice; may return a slice shorter than requested where the
    # array doesn't extend that far, but if the start index is greater than the total length, must return
    # nil. This is consistent with Array#slice/[]
    # eg: [][1..10] == nil, but [][0..10] == []
    #
    # Does not need to handle the other argument types (Range, single index) which Array#slice/[] takes.
    def slice_from_start_and_length(start, length)
      result = []
      stop = start + length
      index = 0
      each do |item|
        break if index >= stop
        result << item if index >= start
        index += 1
      end
      result if index >= start
    end

    # behaviour is consistent with Array#[], except it doesn't take negative indexes.
    # uses slice_from_start_and_length to do the work.
    def [](index_or_range, length=nil)
      case index_or_range
      when Range
        start = index_or_range.begin
        length = index_or_range.end - start
        length += 1 unless index_or_range.exclude_end?
        slice_from_start_and_length(start, length)
      when Integer
        if length
          slice_from_start_and_length(index_or_range, length)
        else
          slice = slice_from_start_and_length(index_or_range, 1) and slice.first
        end
      else
        raise ArgumentError
      end
    end

    alias :slice :[]

    def first
      self[0]
    end

    def last
      l = length
      self[l-1] if l > 0
    end

    # map works lazily, resulting in a LazyData::Array::Mapped or a LazyData::Array::Memoized::Mapped (which additionally
    # memoizes the mapped values)
    def map(memoize=false, &b)
      (memoize ? Memoized::Mapped : Mapped).new(self, &b)
    end

    class Mapped < LazyData::Array
      def initialize(underlying, &block)
        @underlying = underlying; @block = block
      end

      def each
        @underlying.each {|x| yield @block.call(x)}
      end

      def length
        @underlying.length
      end

      def slice_from_start_and_length(start, length)
        @underlying.slice_from_start_and_length(start, length).map(&@block)
      end
    end

    # Memoizes the #length of the array, but does not at present memoize the results of each or slice_from_start_and_length.
    #
    # #length will be memoized as a result of a direct call to #length (which uses an underlying #_length), or
    # as a result of a full iteration via #each (which uses an underlying #_each)
    #
    # Your extension points are now #_each, #_length and #slice_from_start_and_length
    class MemoizedLength < LazyData::Array
      def each
        length = 0
        _each {|item| yield item; length += 1}
        @length = length
        self
      end

      alias :_length :length
      def length
        @length ||= _length
      end

      def inspect
        if @length
          "[LazyData::Array(length=#{@length}):...]"
        else
          "[LazyData::Array:...]"
        end
      end
    end


    # This additionally memoizes the full contents of the array once it's been fully each'd one time.
    # The memoized full contents will then be used for future calls to #each (and hence all the other enumerable
    # methods) and #[]. #to_a directly returns the memoized array once available.
    #
    # As with MemoizedLength, your extension points are now #_each, #_length and #slice_from_start_and_length
    class Memoized < MemoizedLength
      def each(&b)
        if @to_a
          @to_a.each(&b)
        else
          result = []
          _each {|item| yield item; result << item}
          @length = result.length
          @to_a = result
        end
        self
      end

      def to_a
        @to_a || super
      end
      alias :entries :to_a
      alias :to_ary :to_a

      def [](*p)
        @to_a ? @to_a[*p] : super
      end
      alias :slice :[]

      def inspect
        if @to_ary
          "[LazyData::Array: #{@to_ary.inspect[1..-1]}]"
        elsif @length
          "[LazyData::Array(length=#{@length}):...]"
        else
          "[LazyData::Array:...]"
        end
      end

      # For when you want to map to a LazyData::Array which memoizes the results of the map
      class Mapped < Memoized
        def initialize(underlying, &block)
          @underlying = underlying; @block = block
        end

        def _each
          @underlying.each {|x| yield @block.call(x)}
        end

        def _length
          @underlying.length
        end

        def slice_from_start_and_length(start, length)
          @underlying.slice_from_start_and_length(start, length).map(&@block)
        end
      end
    end
  end
end
