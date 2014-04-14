module Representable::JSON
  module Collection
    include Representable::JSON

    def self.included(base)
      base.class_eval do
        include Representable::Hash::Collection
      end
    end
  end
end
