class Representable::Decorator
  module Coercion
    def self.included(base)
      base.class_eval do
        include Virtus
        extend Representable::Coercion::ClassMethods
        extend ClassMethods

        def initialize(represented) # override Virtus' #initialize.
          @represented = represented
        end
      end
    end

    module ClassMethods
      def property(name, options={})
        if options[:type]
          options[:decorator_scope] = true # call setter on decorator so coercion kicks in.
          create_writer(name)
          create_reader(name)
        end

        super # Representable::Coercion.
      end

    private
      # FIXME: dear @solnic, please make this better!
      def create_writer(name)
        # the call to super makes the actual coercion, which is then delegated to the represented instance.
        define_method "#{name}=" do |v|
          coerced_value = super(v).get(self)
          represented.send("#{name}=", coerced_value)
        end
      end

      def create_reader(name)
        # the call to super makes the actual coercion, which is then delegated to the represented instance.
        define_method "#{name}" do
          send("#{name}=", represented.send(name))
          super()
        end
      end
    end
  end
end