require "virtus"

module Representable::Coercion
  class Coercer
    include Virtus

    def coerce(name, v) # TODO: test me.
      # set and get the value as i don't know where exactly coercion happens in virtus.
      send("#{name}=", v)
      send(name)
    end
  end
  # separate coercion object doesn't give us initializer and accessors in the represented object (with module representer)!

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def property(name, args={})
      return super unless args[:type]

      representable_attrs.coercer_class.attribute(name, args[:type])

      # DISCUSS: we add accessors here, basically to provide the same API as before. also, we don't wanna override :getter here, do we?
      # TODO: deprecate these accessors for 1.7 and use coercer.coerce here, too.

      # FIXME: does that actually store the new value in the represented ?
      define_method(name) do
        coercer.send(name)
      end
      define_method("#{name}=") do |v|
        coercer.send("#{name}=", v)
      end

      super
    end

    def representable_attrs
      super.instance_eval do
        def coercer_class
          @coercer_class ||= Class.new(Coercer)
        end
        self
      end
    end
  end

  def coercer
    @coercer ||= representable_attrs.coercer_class.new
  end
end
