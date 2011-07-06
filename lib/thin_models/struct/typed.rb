require 'thin_models/struct'
begin
  require 'typisch'
rescue LoadError
  raise LoadError, "The typisch gem is required if you want to use thin_models/struct/typed"
end

class ThinModels::Struct::Typed < ThinModels::Struct
  include Typisch::Typed

  class << self
    def type_available
      type.property_names_to_types.map do |name, type|
        attribute(name) unless attributes.include?(name) || method_defined?(name)
        alias_method(:"#{name}?", name) if type.excluding_null.is_a?(Typisch::Type::Boolean)
      end
    end
  end

  # this will only type-check non-lazy properties -- not much point
  # passing lazy properties if it's going to eagerly fetch them right
  # away just to type-check them.
  def check_attributes
    self.class.type.property_names.each do |property|
      type_check_property(property) if @values.has_key?(property)
    end
  end

  def []=(attribute, value)
    raise NameError, "no attribute #{attribute.inspect} in #{self.class}" unless self.class.attributes.include?(attribute)
    @values[attribute] = value
    type_check_property(attribute)
  end
end
