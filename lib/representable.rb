require 'representable/config'
require 'representable/definition'
require 'representable/for_collection'
require 'representable/represent'
require 'representable/declarative'
require 'representable/apply'
require "representable/deserializer"
require "representable/serializer"

require "uber/delegates"
require "representable/binding"

require "uber/callable"
require "representable/pipeline"
require "representable/insert" # Pipeline::Insert
require "representable/cached"

module Representable
  attr_writer :representable_attrs

  def self.included(base)
    base.class_eval do
      extend Declarative
      extend ClassInclusions, ModuleExtensions
      extend ClassMethods
      extend Feature
      extend ForCollection
      extend Represent
      extend Apply
      # register_feature Representable # Representable gets included automatically when creating inline representer.
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
    @representable_attrs ||= self.class.representable_attrs # DISCUSS: copy, or better not? what about "freezing"?
  end

  def representation_wrap(*args)
    representable_attrs.wrap_for(nil, represented, *args) { self.class.name }
  end

  def represented
    self
  end

  module ClassInclusions
    def included(includer)
      super
      heritage.(includer)
    end

    def inherited(subclass) # DISCUSS: this could be in Decorator? but then we couldn't do B < A(include X) for non-decorators, right?
      super
      heritage.(subclass)
    end
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


  module Feature
    def feature(*mods)
      mods.each do |mod|
        include mod
        register_feature(mod)
      end
    end

  private
    def register_feature(mod)
      heritage.record(:feature, mod) # TODO: move to ::feature.

      representable_attrs[:features][mod] = true
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
