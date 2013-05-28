require 'representable/coercion'

class Representable::Decorator
  module Coercion
    def self.included(base)
      base.class_eval do
        # DISCUSS: this assumes we have a Representer included, yet.
        alias_method :representable_initialize, :initialize
        alias_method :representable_to_hash,    :to_hash

        # FIXME: allow including coercion only from virtus.
        include Virtus
        undef_method(:initialize)
        undef_method(:to_hash)

        extend Representable::Coercion::ClassMethods
        extend ClassMethods

        def initialize(*args) # override Virtus' #initialize.
          representable_initialize(*args)
        end

        def to_hash(*args) # override Virtus' #to_hash.
          representable_to_hash(*args)
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