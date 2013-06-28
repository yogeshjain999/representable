require 'representable/feature/readable_writeable'

module Representable
  # Render and parse by looping over the representer's properties and dispatching to bindings.
  # Conditionals are handled here, too.
  class Mapper
    module Methods
      def initialize(bindings, represented, representer)
        @bindings     = bindings
        @represented  = represented # the (extended) model.
        @representer  = representer # this is used as the Binding#exec_context. should be called decorator.
      end

      def deserialize(doc, options)
        bindings.each do |bin|
          deserialize_property(bin, doc, options)
        end
        represented
      end

      def serialize(doc, options)
        bindings.each do |bin|
          serialize_property(bin, doc, options)
        end
        doc
      end

    private
      attr_reader :bindings, :represented, :representer

      def serialize_property(binding, doc, options)
        return if skip_property?(binding, options)
        compile_fragment(binding, doc)
      end

      def deserialize_property(binding, doc, options)
        return if skip_property?(binding, options)
        uncompile_fragment(binding, doc)
      end

      # Checks and returns if the property should be included.
      def skip_property?(binding, options)
        return true if skip_excluded_property?(binding, options)  # no need for further evaluation when :exclude'ed

        skip_conditional_property?(binding)
      end

      def skip_excluded_property?(binding, options)
        return unless props = options[:exclude] || options[:include]
        res   = props.include?(binding.name.to_sym)
        options[:include] ? !res : res
      end

      def skip_conditional_property?(binding)
        # TODO: move to Binding.
        return unless condition = binding.options[:if]

        args = []
        args << binding.user_options if condition.arity > 0 # TODO: remove arity check. users should know whether they pass options or not.

        not represented.instance_exec(*args, &condition)
      end

      def compile_fragment(bin, doc)
        bin.compile_fragment(doc)
      end

      def uncompile_fragment(bin, doc)
        bin.uncompile_fragment(doc)
      end
    end

    include Methods
    include Feature::ReadableWriteable # DISCUSS: make this pluggable.
  end
end