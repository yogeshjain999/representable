module Representable
  # NOTE: the API of Config is subject to change so don't rely too much on this private object.
  class Config < Array # TODO: change to Hash.
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

    # def <<(definition)
    #   self[definition.name] = definition
    #   self
    # end
    # def last
    #   self.values.last
    # end
    # def push(config={}) # FIXME: why do we need a default arg here?
    #   puts "merging: #{config.inspect} with self: #{self.inspect}"
    #   merge!(config)
    # end
    # def each(&block)
    #   values.each(&block)
    # end

    def <<(definition)
      if overridden = find { |d| d.name == definition.name }
        self[index(overridden)] = definition
        return self
      end

      super(definition)
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
    def push(*defs)
      defs.each { |d| self << d }
    end

    def infer_name_for(name)
      name.to_s.split('::').last.
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       downcase
    end
  end
end