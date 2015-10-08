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
          uncompile_fragment(bin, doc)
        end
        represented
      end

      def serialize(represented, doc, options, private_options)
        bindings(represented, options).each do |bin|
          compile_fragment(bin, doc)
        end
        doc
      end

    private
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