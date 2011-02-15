module LazyData

  class Struct
    def initialize(values={}, &lazy_values)
      @values = values
      @lazy_values = lazy_values if lazy_values
    end

    def [](attribute)
      @values[attribute]
    end

    def []=(attribute, value)
      @values[attribute] = value
    end

    def has_key?(attribute)
      @values.has_key?(attribute)
    end
    alias :has_attribute? :has_key?

    def inspect
      super.sub(/@lazy_values=#<Proc:.*?>/, 'lazy')
    end

    def self.lazy_attr_reader(*attributes)
      attributes.each do |attribute|
        class_eval <<-EOS, __FILE__, __LINE__+1
          def #{attribute}
            if @values.has_key?(:#{attribute})
              @values[:#{attribute}]
            elsif @lazy_values
              @values[:#{attribute}] = @lazy_values.call(:#{attribute})
            end
          end
        EOS
      end
    end

    def self.lazy_attr_writer(*attributes)
      attributes.each do |attribute|
        class_eval <<-EOS, __FILE__, __LINE__+1
          def #{attribute}=(value)
            @values[:#{attribute}] = value
          end
        EOS
      end
    end

    def self.lazy_attr_accessor(*attributes)
      lazy_attr_reader(*attributes)
      lazy_attr_writer(*attributes)
    end
  end

  def self.Struct(*attributes)
    Class.new(Struct) {lazy_attr_accessor(*attributes)}
  end

end
