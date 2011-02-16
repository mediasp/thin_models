require 'lazy-data/errors'
require 'set'

module LazyData

  class Struct
    def initialize(values=nil, &lazy_values)
      if values
        attributes = self.class.attributes
        values.each_key do |attribute|
          raise NameError, "no attribute #{attribute} in #{self.class}" unless attributes.include?(attribute)
        end
      end
      @values = values || {}
      @lazy_values = lazy_values if lazy_values
    end

    # this allows 'dup' to work in a desirable way for these instances,
    # ie use a dup'd properties hash instance for the dup, meaning it can
    # be updated without affecting the state of the original.
    def initialize_copy(other)
      @values = @values.dup
    end

    def freeze
      super
      @values.freeze
    end

    def loaded_attributes
      @values.dup
    end

    # This helps these structs work with ruby methods, like merge, which expect a Hash.
    alias :to_hash :loaded_attributes

    def attribute_loaded?(attribute)
      @values.has_key?(attribute)
    end

    attr_accessor :lazy_values
    private :lazy_values=

    def remove_lazy_values
      remove_instance_variable(:@lazy_values) if instance_variable_defined?(:@lazy_values)
    end

    def has_lazy_values?
      instance_variable_defined?(:@lazy_values)
    end

    def attributes
      self.class.attributes
    end

    def [](attribute)
      if @values.has_key?(attribute)
        @values[attribute]
      else
        raise NameError, "no attribute #{attribute} in #{self.class}" unless self.class.attributes.include?(attribute)
        if @lazy_values
          @values[attribute] = @lazy_values.call(self, attribute)
        else
          raise PartialDataError, "attribute #{attribute} not loaded"
        end
      end
    end

    # modifying the struct makes it stop any further lazy loading and forget about its lazy_values.
    # since it only really makes sense to me for an immutable object to be lazily loaded, potential for state bugs otherwise
    def []=(attribute, value)
      raise NameError, "no attribute #{attribute} in #{self.class}" unless self.class.attributes.include?(attribute)
      remove_lazy_values
      @values[attribute] = value
    end

    def merge(updated_values)
      dup.merge!(updated_values)
    end

    def merge!(updated_values)
      updated_values.to_hash.each_key do |attribute|
        raise NameError, "no attribute #{attribute} in #{self.class}" unless attributes.include?(attribute)
      end
      remove_lazy_values
      @values.merge!(updated_values)
      self
    end

    def inspect
      super.sub(/@lazy_values=#<Proc:.*?>/, 'lazy')
    end


    class << self
      def attributes
        @attributes ||= (superclass < Struct ? superclass.attributes.dup : Set.new)
      end

      private

      def lazy_attr_reader(*attributes)
        attributes.each do |attribute|
          raise "Attribute #{attribute} already defined on #{self}" if self.attributes.include?(attribute)
          self.attributes << attribute
          class_eval <<-EOS, __FILE__, __LINE__+1
            def #{attribute}
              if @values.has_key?(:#{attribute})
                @values[:#{attribute}]
              elsif @lazy_values
                @values[:#{attribute}] = @lazy_values.call(self, :#{attribute})
              else
                raise PartialDataError, "attribute #{attribute} not loaded"
              end
            end
          EOS
        end
      end

      def lazy_attr_accessor(*attributes)
        lazy_attr_reader(*attributes)
        attributes.each do |attribute|
          class_eval <<-EOS, __FILE__, __LINE__+1
            def #{attribute}=(value)
              remove_lazy_values
              @values[:#{attribute}] = value
            end
          EOS
        end
      end

      # the identity attribute is not lazily-loaded, nor does it have a public setter.
      # it does get registered as an attribute though.
      def identity_attr
        include IdentityMethods
        attributes << :id
      end
    end

    module IdentityMethods
      def id
        @values[:id]
      end

      def ==(other)
        super || (other.is_a?(self.class) && (id = self.id) && other.id == id) || false
      end

      def hash
        id ? id.hash : super
      end

      # this was: alias :eql? :==, but that ran into http://redmine.ruby-lang.org/issues/show/734
      def eql?(other)
        super || (other.is_a?(self.class) && (id = self.id) && other.id == id) || false
      end

    private

      def id=(id)
        @values[:id] = id
      end
    end
  end

  # todo: add a ? to boolean getters

  def self.Struct(*attributes)
    Class.new(Struct) do
      lazy_attr_accessor(*attributes)
    end
  end

  def self.StructWithIdentity(*attributes)
    Class.new(Struct) do
      identity_attr
      lazy_attr_accessor(*attributes)
    end
  end

end
