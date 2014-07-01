require "virtus"

module Representable
  module Coercion
    class Coercer
      def call(value, options)
        Virtus::Attribute.build(options.binding[:type]).coerce(value)
      end
    end


    def self.included(base)
      base.extend ClassMethods
      # !!! REGISTER FEATURE, TEST
    end


    module ClassMethods
      def property(name, options={})
        return super unless options[:type]

        options = options.merge(
          :pass_options  => true,
          :render_filter => coercer = Pipeline[Coercer.new],
          :parse_filter  => coercer
        )

        super
      end
    end
  end
end