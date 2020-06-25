# frozen_string_literal: true

module Representable
  module Hash
    module AllowSymbols
    private

      def filter_wrap_for(data, *args)
        super(Conversion.stringify_keys(data), *args)
      end

      def update_properties_from(data, *args)
        super(Conversion.stringify_keys(data), *args)
      end
    end

    module Conversion
      def stringify_keys(hash)
        mutate_keys(hash, :to_s)
      end

      def symbolize_keys(hash)
        mutate_keys(hash, :to_sym)
      end
      module_function :stringify_keys, :symbolize_keys

      def self.mutate_keys(hash, method)
        hash.each_with_object({}) do |(k, v), new_hash|
          new_hash[k.send(method)] = if v.is_a?(Hash)
                                        mutate_keys(v, method)
                               elsif v.is_a?(Array)
                                 v.map { |h| h.is_a?(Hash) ? mutate_keys(h, method) : h }
                               else
                                 v
                               end
        end
      end
    end
  end
end
