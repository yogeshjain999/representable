module Representable
  # Render and parse by looping over the representer's properties and dispatching to bindings.
  # Conditionals are handled here, too.
  class Mapper
    module Methods
      def initialize(bindings)
        @bindings = bindings
      end

      def bindings(represented, options)
        @bindings.each do |binding|
          binding.update!(represented, options)
        end
      end

      def deserialize(represented, doc, options, private_options)
        bindings(represented, options).each do |bin|
          deserialize_property(bin, doc, options, private_options)
        end
        represented
      end

      def serialize(represented, doc, options, private_options)
        bindings(represented, options).each do |bin|
          serialize_property(bin, doc, options, private_options)
        end
        doc
      end

    private
      def serialize_property(binding, doc, options, private_options)
        return if skip_property?(binding, private_options.merge(:action => :serialize))
        compile_fragment(binding, doc)
      end

      def deserialize_property(binding, doc, options, private_options)
        return if skip_property?(binding, private_options.merge(:action => :deserialize))
        uncompile_fragment(binding, doc)
      end

      def skip_property?(binding, private_options)
        return unless private_options[:include] || private_options[:exclude] || binding.skip_filters?

        return true if skip_excluded_property?(binding, private_options)  # no need for further evaluation when :exclude'ed
      end

      def skip_excluded_property?(binding, private_options)
        return unless props = private_options[:exclude] || private_options[:include]
        res   = props.include?(binding.name.to_sym)
        private_options[:include] ? !res : res
      end

      def compile_fragment(bin, doc)
        bin.compile_fragment(doc)
      end

      def uncompile_fragment(bin, doc)
        bin.uncompile_fragment(doc)
      end
    end

    include Methods
  end
end