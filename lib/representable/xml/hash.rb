require 'representable/xml'
require 'representable/hash_methods'

module Representable::XML
  module AttributeHash
    include Representable::XML
    include Representable::HashMethods

    def self.included(base)
      raise "[Representable] Sorry, XML::AttributeHash is no longer working in Representable 2.4. This is because the authors are too busy working on other OSS stuff, for free. You can sponsor improving Representable's XML layer: http://trailblazerb.org/inc/sponsoring.html"
      base.class_eval do
        include Representable
        extend ClassMethods
        representable_attrs.add(:_self, {:hash => true, :use_attributes => true})
      end
    end


    module ClassMethods
      def values(options)
        hash :_self, options.merge!(:use_attributes => true)
      end
    end

    def method_name
      bin = representable_mapper(format, options).bindings(represented, options).first
      bin.write(doc, super)
    end
  end

  module Hash
    include Representable::XML
    include HashMethods

    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        representable_attrs.add(:_self, {:hash => true})
      end
    end


    module ClassMethods
      def values(options)
        hash :_self, options
      end
    end
  end
end
