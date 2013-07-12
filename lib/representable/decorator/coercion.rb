require 'representable/coercion'

class Representable::Decorator
  module Coercion
    def self.included(base)
      base.class_eval do
        include Representable::Coercion
      end
    end
  end
end