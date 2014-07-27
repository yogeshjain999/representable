require "virtus"

module Representable
  module Coercion
    class Coercer
      def call(value, doc, options)
        Virtus::Attribute.build(options.binding[:type]).coerce(value)
      end
    end


    def self.included(base)
      base.class_eval do
        extend ClassMethods
        register_feature Coercion
      end
    end


    module ClassMethods
      def build_definition(name, options, &block) # Representable::Declarative
        return super unless type = options[:type]

        options[:pass_options]  = true # TODO: remove, standard.

        options[:render_filter] << coercer = Coercer.new
        options[:parse_filter]  << coercer

        super
      end
    end
  end
end