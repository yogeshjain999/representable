module Representable
  module HashMethods
    def create_representation_with(doc, options, format)
      hash  = filter_keys_for!(represented, options) # FIXME: this modifies options and replicates logic from Representable.
      bin   = representable_mapper(format, options).bindings(represented, options).first

      # FIXME: not finished, yet!
      return Pipeline[Serialize, Write].({doc: doc, result: hash, user_options: options, binding: bin})
    end

    def update_properties_from(doc, options, format)
      hash  = filter_keys_for!(doc, options)
      bin   = representable_mapper(format, options).bindings(represented, options).first

      # TODO: instantiate pipeline via binding so we have central place to inject debugging.
      value = Collect::Hash[*bin.send(:default_fragment_functions)].(fragment: hash, document: doc, binding: bin)

      represented.replace(value)
    end

  private
    def filter_keys_for!(hash, options)
      excluding = options[:exclude]
      # TODO: use same filtering method as in normal representer in Representable#create_representation_with.
      return hash unless props = options.delete(:exclude) || options.delete(:include)
      hash.reject { |k,v| excluding ? props.include?(k.to_sym) : !props.include?(k.to_sym) }
    end
  end
end
