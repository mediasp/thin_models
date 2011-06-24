require 'thin_models/struct'

module ThinModels

  module Struct::IdentityMethods
    def self.included(klass)
      raise "#{self} only applies to ThinModels::Struct subclasses" unless klass < Struct
      klass.attributes << :id
    end

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

  class Struct
    class << self
    private
      def identity_attribute
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
