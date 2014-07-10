module Representable
  module Schema
    def self.included(base)
      base.send(:include, Representable)
    #   base.feature Representable
    #   base.extend Included
    end


    # module Included
    #   def included(base)
    #     puts "#{self} included into #{base}"
    #     super # base.inherit!(self)

    #     base.representable_attrs.each do |cfg|
    #       next unless mod = cfg.representer_module # only nested decorator.

    #       inline_representer = base.inline_for(mod) # the includer controls what "wraps" the module.
    #       cfg.merge!(:extend => inline_representer)
    #     end
    #   end
    # end
  end
end