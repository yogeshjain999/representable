module Representable::XML
  module Collection
    include Representable::XML

    def self.included(base)
      base.class_eval do
        include Representable::Hash::Collection
        include Methods
      end
    end

    module Methods
      def update_properties_from(doc, *args)
        super(doc.search("./*"), *args) # pass the list of collection items to Hash::Collection#update_properties_from.
      end
    end
  end
end
