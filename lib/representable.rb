require 'representable/definition'
require 'representable/mapper'
require 'representable/config'
require "representable/parse_strategies"


module Representable
  attr_writer :representable_attrs

  def self.included(base)
    base.class_eval do
      extend ClassInclusions, ModuleExtensions
      extend ClassMethods
      extend ClassMethods::Declarations
      extend DSLAdditions
    end
  end

private
  # Reads values from +doc+ and sets properties accordingly.
  def update_properties_from(doc, options, format)
    # deserialize_for(bindings, mapper ? , options)
    representable_mapper(format, options).deserialize(doc, options)
  end

  # Compiles the document going through all properties.
  def create_representation_with(doc, options, format)
    representable_mapper(format, options).serialize(doc, options)
  end

  def representable_bindings_for(format, options)
    options = cleanup_options(options)  # FIXME: make representable-options and user-options  two different hashes.
    representable_attrs.collect {|attr| representable_binding_for(attr, format, options) }
  end

  def representable_binding_for(attribute, format, options)
    format.build(attribute, represented, self, options)
  end

  def cleanup_options(options) # TODO: remove me. this clearly belongs in Representable.
    options.reject { |k,v| [:include, :exclude].include?(k) }
  end

  def representable_attrs
    @representable_attrs ||= self.class.representable_attrs # DISCUSS: copy, or better not?
  end

  def representable_mapper(format, options)
    bindings = representable_bindings_for(format, options)
    Mapper.new(bindings, represented, options) # TODO: remove self, or do we need it? and also represented!
  end


  def representation_wrap(*args)
    representable_attrs.wrap_for(self.class.name, represented, *args)
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
      object.representable_attrs=(representable_attrs) # yes, we want a hard overwrite here and no inheritance.
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

      def property(name, options={}, &block)
        representable_attrs << definition_class.new(name, options)
      end

      def collection(name, options={}, &block)
        options[:collection] = true # FIXME: don't override original.
        property(name, options, &block)
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
    end # Declarations
  end

  # Internal module for DSL sugar that should not go into the core library.
  module DSLAdditions
    # Allows you to nest a block of properties in a separate section while still mapping them to the outer object.
    def nested(name, options={}, &block)
      options = options.merge(
        :use_decorator => true,
        :getter        => lambda { |*| self },
        :setter        => lambda { |*| },
        :instance      => lambda { |*| self }
      )

      property(name, options, &block)
    end

    def property(name, options={}, &block)
      modules = []

      if options[:inherit] # TODO: move this to Definition.
        parent  = representable_attrs[name]
        modules << parent[:extend].evaluate(nil) if parent[:extend]# we can savely assume this is _not_ a lambda. # DISCUSS: leave that in #representer_module?
      end # FIXME: can we handle this in super/Definition.new ?

      if block_given?
        handle_deprecated_inline_extend!(modules, options)

        options[:extend] = inline_representer_for(modules, name, options, &block)
      end

      return parent.merge!(options) if options.delete(:inherit)

      super
    end

    def inline_representer(base_module, name, options, &block) # DISCUSS: separate module?
      Module.new do
        include *base_module # Representable::JSON or similar.
        instance_exec &block
      end
    end

  private
    def inline_representer_for(modules, name, options, &block)
      representer = options[:use_decorator] ? Decorator : self
      modules     = [representer_engine] + modules

      representer.inline_representer(modules.compact.reverse, name, options, &block)
    end

    def handle_deprecated_inline_extend!(modules, options) # TODO: remove in 2.0.
      return unless include_module = options.delete(:extend) and not options[:inherit]

      warn "[Representable] Using :extend with an inline representer is deprecated. Include the module in the inline block."
      modules << include_module
    end
  end # DSLAdditions
end

require 'representable/decorator'
