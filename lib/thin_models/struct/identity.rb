require 'thin_models/struct'

module ThinModels

  module Struct::IdentityMethods
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
  end

  class Struct
    class << self
    private
      def identity_attribute(name=:id)
        attribute(name) unless attributes.include?(name)
        alias_method(:id=, "#{name}=") unless name == :id
        class_eval <<-EOS, __FILE__, __LINE__+1
          def id
            @values[#{name.inspect}]
          end
        EOS
        include IdentityMethods
      end
    end
  end

  def self.StructWithIdentity(*attributes)
    Class.new(Struct) do
      identity_attribute
      attributes.each {|a| attribute(a)}
    end
  end
end
