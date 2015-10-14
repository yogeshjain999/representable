module Representable
  # Render and parse by looping over the representer's properties and dispatching to bindings.
  # Conditionals are handled here, too.
  class Mapper
    module Methods
      def initialize(bindings)
        @bindings = bindings
      end

      attr_reader :bindings

      def deserialize(represented, doc, options)
        options = {doc: doc, _private: options[:_private], user_options: options, represented: represented}

        bindings.each do |bin|
          uncompile_fragment(bin, options)
        end
        represented
      end

      def serialize(represented, doc, options) # options {is_admin: true, _private: {}}
        options = {doc: doc, _private: options[:_private], user_options: options, represented: represented}

        bindings.each do |bin|
          compile_fragment(bin, options)
        end
        doc
      end

    private
      def compile_fragment(bin, options)
        options[:binding] = bin

        bin.compile_fragment(options)
      end

      def uncompile_fragment(bin, options)
        options[:binding] = bin

        bin.uncompile_fragment(options)
      end
    end

    include Methods
  end
end