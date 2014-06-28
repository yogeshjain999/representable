require 'representable/json'
require 'representable/hash_methods'

module Representable::JSON
  # "Lonely Hash" support.
  module Hash
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        include Representable::JSON
        include Representable::HashMethods
      end
    end


    module ClassMethods
      def values(options, &block)
        hash(:_self, options, &block)
      end
    end


    def definition_opts
      [:_self, {:hash => true, :use_attributes => true}]
    end
  end
end
