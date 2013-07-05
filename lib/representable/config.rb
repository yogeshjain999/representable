module Representable
  # NOTE: the API of Config is subject to change so don't rely too much on this private object.
  class Config < Array
    # DISCUSS: experimental. this will soon be moved to a separate gem
    module InheritableArray
      def inheritable_array(name)
        inheritable_arrays[name] ||= []
      end
      def inheritable_arrays
        @inheritable_arrays ||= {}
      end

      def inherit(parent)
        super

        parent.inheritable_arrays.keys.each do |k|
          inheritable_array(k).push *parent.inheritable_array(k).clone
        end
      end
    end


    attr_accessor :wrap

    # Computes the wrap string or returns false.
    def wrap_for(name)
      return unless wrap
      return infer_name_for(name) if wrap === true
      wrap
    end

    module InheritMethods
      def clone
        self.class.new(collect { |d| d.clone })
      end

      def inherit(parent)
        push(*parent.clone)
      end
    end
    include InheritMethods
    include InheritableArray # overrides #inherit.

  private
    def infer_name_for(name)
      name.to_s.split('::').last.
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       downcase
    end
  end
end