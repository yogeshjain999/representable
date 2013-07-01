require 'representable/coercion'

class Representable::Decorator
  module Coercion
    def self.included(base)
      base.class_eval do
        include Representable::Coercion
        extend ClassMethods
      end
    end

    module ClassMethods
      def property(name, options={})
        if options[:type]
          options[:decorator_scope] = true
          options[:getter] = lambda { |*| coercer.coerce(name, decorated.send(name)) }
          options[:setter] = lambda { |v,*| decorated.send("#{name}=", coercer.coerce(name, v)) }
        end

        super # Representable::Coercion.
      end
    end
  end
end