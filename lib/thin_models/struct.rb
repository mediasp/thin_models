require 'thin_models/errors'
require 'set'

module ThinModels

  class Struct
    def self.new_skipping_checks(values, &lazy_values)
      new(values, true, &lazy_values)
    end

    def initialize(values=nil, skip_checks=false, &lazy_values)
      @values = (values || {}).reduce({}) { |m, (k, v)| m[k.to_sym] = v; m }
      @lazy_values = lazy_values if lazy_values
      check_attributes if values && !skip_checks
    end

    def check_attributes
      @values.each_key do |attribute|
        check_attribute(attribute)
      end
    end

    def check_attribute(attribute)
      attributes = self.class.attributes.map(&:to_s)
      unless attributes.include?(attribute.to_s)
        fail NameError, "no attribute #{attribute} in #{self.class}"
      end
    end

    # this allows 'dup' to work in a desirable way for these instances,
    # ie use a dup'd properties hash instance for the dup, meaning it can
    # be updated without affecting the state of the original.
    def initialize_copy(other)
      super
      @values = @values.dup
    end

    def freeze
      super
      @values.freeze
    end

    def loaded_values
      @values.dup
    end

    # This helps these structs work with ruby methods, like merge, which expect a Hash.
    alias :to_hash :loaded_values

    def attribute_loaded?(attribute)
      @values.has_key?(attribute)
    end
    alias :has_key? :attribute_loaded?
    alias :key? :attribute_loaded?

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

    def loaded_attributes
      @values.keys
    end
    alias :keys :loaded_attributes

    def [](attribute)
      check_attribute(attribute)
      attribute = attribute.to_sym
      if @values.has_key?(attribute.to_sym)
        @values[attribute.to_sym]
      else
        if @lazy_values
          @values[attribute] = @lazy_values.call(self, attribute)
        end
      end
    end

    def fetch(attribute)
      check_attribute(attribute)
      attribute = attribute.to_sym
      if @values.has_key?(attribute)
        @values[attribute]
      else
        if @lazy_values
          @values[attribute] = @lazy_values.call(self, attribute)
        else
          raise PartialDataError, "attribute #{attribute} not loaded"
        end
      end
    end

    def []=(attribute, value)
      check_attribute(attribute)
      attribute = attribute.to_sym
      @values[attribute] = value
    end

    def merge(updated_values)
      dup.merge!(updated_values)
    end

    def merge!(updated_values)
      updated_values.to_hash.each_key do |attribute|
        check_attribute(attribute)
      end
      @values.merge!(updated_values)
      self
    end

    # Based on Matz's code for OpenStruct#inspect in the stdlib.
    #
    # Note the trick with the Thread-local :__inspect_key__, which ruby internals appear to
    # use but  isn't documented anywhere. If you use it in the same way the stdlib uses it,
    # you can override inspect without breaking its cycle avoidant behaviour
    def inspect
      str = "#<#{self.class}"

      ids = (Thread.current[:__inspect_key__] ||= [])
      if ids.include?(object_id)
        return str << ' ...>'
      end

      ids << object_id
      begin
        first = true
        for k,v in @values
          str << "," unless first
          first = false
          str << " #{k}=#{v.inspect}"
        end
        if @lazy_values
          str << "," unless first
          str << " ..."
        end
        return str << '>'
      ensure
        ids.pop
      end
    end
    alias :to_s :inspect

    def to_json(*p)
      @values.merge(:json_class => self.class).to_json(*p)
    end

    def self.json_create(json_values)
      values = {}
      attributes.each {|a| values[a] = json_values[a.to_s] if json_values.has_key?(a.to_s)}
      new(values)
    end


    class << self
      def attributes
        @attributes ||= (superclass < Struct ? superclass.attributes.dup : Set.new)
      end

      private

      def attribute(attribute)
        raise "Attribute #{attribute} already defined on #{self}" if self.attributes.include?(attribute)
        self.attributes << attribute
        class_eval <<-EOS, __FILE__, __LINE__+1
          def #{attribute}
            fetch(#{attribute.inspect})
          end
        EOS
        class_eval <<-EOS, __FILE__, __LINE__+1
          def #{attribute}=(value)
            self[#{attribute.inspect}] = value
          end
        EOS
      end
    end
  end

  # todo: add a ? to boolean getters

  def self.Struct(*attributes)
    Class.new(Struct) do
      attributes.each {|a| attribute(a)}
    end
  end
end

require 'thin_models/struct/identity'
