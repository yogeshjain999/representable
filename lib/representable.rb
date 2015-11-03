require "uber/delegates"

require "declarative/schema"

require "representable/config"
require "representable/definition"
require "representable/declarative"
require "representable/deserializer"
require "representable/serializer"
require "representable/binding"
require "representable/pipeline"
require "representable/insert" # Pipeline::Insert
require "representable/cached"
require "representable/for_collection"
require "representable/represent"

module Representable
  attr_writer :representable_attrs

  def self.included(base)
    base.class_eval do
      extend Declarative
      # make Representable horizontally and vertically inheritable.
      extend ModuleExtensions, ::Declarative::Heritage::Inherited, ::Declarative::Heritage::Included
      extend ClassMethods
      extend ForCollection
      extend Represent
    end
  end

private
  # Reads values from +doc+ and sets properties accordingly.
  def update_properties_from(doc, options, format)
    propagated_options = normalize_options(options)

    representable_map!(doc, propagated_options, format, :uncompile_fragment)
    represented
  end

  # Compiles the document going through all properties.
  def create_representation_with(doc, options, format)
    propagated_options = normalize_options(options) # {_private: {include: }, is_admin: true}

    representable_map!(doc, propagated_options, format, :compile_fragment)
    doc
  end

  class Binding::Map < Array
    def call(method, options)
      each do |bin|
        options[:binding] = bin # this is so much faster than options.merge().
        bin.send(method, options)
      end
    end

     # TODO: Merge with Definitions.
    def <<(binding) # can be slow. this is compile time code.
      (existing = find { |bin| bin.name == binding.name }) ? self[index(existing)] = binding : super(binding)
    end
  end

  def representable_map(options, format)
    Binding::Map.new(representable_bindings_for(format, options))
  end

  def representable_map!(doc, propagated_options, format, method)
    options = {doc: doc, _private: propagated_options[:_private], user_options: propagated_options, represented: represented, decorator: self}

    representable_map(options, format).(method, options) # .(:uncompile_fragment, options)
  end

  def representable_bindings_for(format, options)
    representable_attrs.collect {|definition| format.build(definition) }
  end

  # Make sure we do not change original options. However, private options like :include or :wrap are
  # not passed on to child representers.
  def normalize_options(options)
    # here, we could also filter out local options e.g. like options[:band].
    return options unless options.any?

    propagated_options = options.dup
    propagated_options.delete(:wrap) # FIXME.
    propagated_options.delete(:_private)

    private_options = {}
    private_options[:include] = propagated_options.delete(:include) if options[:include]
    private_options[:exclude] = propagated_options.delete(:exclude) if options[:exclude]

    propagated_options[:_private] = private_options if private_options.any?

    propagated_options
  end

  def representable_attrs
    @representable_attrs ||= self.class.definitions
  end

  def representation_wrap(*args)
    representable_attrs.wrap_for(represented, *args)
  end

  def represented
    self
  end

  module ModuleExtensions
    # Copies the representable_attrs reference to the extended object.
    # Note that changing attrs in the instance will affect the class configuration.
    def extended(object)
      super
      object.representable_attrs=(representable_attrs) # yes, we want a hard overwrite here and no inheritance.
    end
  end

  module ClassMethods
    def prepare(represented)
      represented.extend(self)
    end
  end

  require "representable/deprecations"
  def self.deprecations=(value)
    evaluator = value==false ? Binding::EvaluateOption : Binding::Deprecation::EvaluateOption
    ::Representable::Binding.send :include, evaluator
  end
  self.deprecations = true # TODO: change to false in 2.5 or remove entirely.
end

require 'representable/autoload'
