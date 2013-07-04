require 'representable/deprecations'
require 'representable/definition'
require 'representable/mapper'

# Representable can be used in two ways.
#
# == On class level
#
# To try out Representable you might include the format module into the represented class directly and then
# define the properties.
#
#   class Hero < ActiveRecord::Base
#     include Representable::JSON
#     property :name
#
# This will give you to_/from_json for each instance. However, this approach limits your class to one representation.
#
# == On module level
#
# Modules give you much more flexibility since you can mix them into objects at runtime, following the DCI
# pattern.
#
#   module HeroRepresenter
#     include Representable::JSON
#     property :name
#   end
#
#   hero.extend(HeroRepresenter).to_json
module Representable
  attr_writer :representable_attrs

  def self.included(base)
    base.class_eval do
      extend ClassInclusions, ModuleExtensions
      extend ClassMethods
      extend ClassMethods::Declarations

      include Deprecations

    end
  end

  # Reads values from +doc+ and sets properties accordingly.
  def update_properties_from(doc, options, format)
    representable_mapper(format, options).deserialize(doc, options)
  end

private
  # Compiles the document going through all properties.
  def create_representation_with(doc, options, format)
    representable_mapper(format, options).serialize(doc, options)
  end

  def representable_attrs
    @representable_attrs ||= self.class.representable_attrs # DISCUSS: copy, or better not?
  end

  def representable_mapper(format, options)
    # DISCUSS: passing all those options by intention: i want to point out that there's still lots of dependencies.
    Mapper.new(representable_attrs, represented, self, format, options)
  end



  def representation_wrap
    representable_attrs.wrap_for(self.class.name)
  end

  def represented
    self
  end

  module ClassInclusions
    def included(base)
      super
      base.representable_attrs.inherit(representable_attrs)
    end

    def inherited(base) # DISCUSS: this could be in Decorator? but then we couldn't do B < A(include X) for non-decorators, right?
      super
      base.representable_attrs.inherit(representable_attrs)
    end
  end

  module ModuleExtensions
    # Copies the representable_attrs to the extended object.
    def extended(object)
      super
      object.representable_attrs=(representable_attrs)
    end
  end


  module ClassMethods
    # Create and yield object and options. Called in .from_json and friends.
    def create_represented(document, *args)
      new.tap do |represented|
        yield represented, *args if block_given?
      end
    end

    def prepare(represented)
      represented.extend(self)  # was: PrepareStrategy::Extend.
    end


    module Declarations
      def representable_attrs
        @representable_attrs ||= build_config
      end

      def representation_wrap=(name)
        representable_attrs.wrap = name
      end

      # Declares a represented document node, which is usually a XML tag or a JSON key.
      #
      # Examples:
      #
      #   property :name
      #   property :name, :from => :title
      #   property :name, :class => Name
      #   property :name, :default => "Mike"
      #   property :name, :render_nil => true
      #   property :name, :readable => false
      #   property :name, :writeable => false
      def property(name, options={})
        representable_attrs << definition_class.new(name, options)
      end

      # Declares a represented document node collection.
      #
      # Examples:
      #
      #   collection :products
      #   collection :products, :from => :item
      #   collection :products, :class => Product
      def collection(name, options={})
        options[:collection] = true
        property(name, options)
      end

      def hash(name=nil, options={})
        return super() unless name  # allow Object.hash.

        options[:hash] = true
        property(name, options)
      end

    private
      def definition_class
        Definition
      end

      def build_config
        Config.new
      end
    end
  end


  # NOTE: the API of Config is subject to change so don't rely too much on this private object.
  class Config < Array
    attr_accessor :wrap

    # Computes the wrap string or returns false.
    def wrap_for(name)
      return unless wrap
      return infer_name_for(name) if wrap === true
      wrap
    end

    def clone
      self.class.new(collect { |d| d.clone })
    end

    def inherit(parent)
      push(*parent.clone)
    end

  private
    def infer_name_for(name)
      name.to_s.split('::').last.
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       downcase
    end
  end
end

require 'representable/decorator'
