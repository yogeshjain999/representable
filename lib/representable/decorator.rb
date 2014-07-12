module Representable
  class Decorator
    attr_reader :represented
    alias_method :decorated, :represented

    # TODO: when moving all class methods into ClassMethods, i get a segfault.
    def self.prepare(represented)
      new(represented)
    end

    def self.default_inline_class
      Representable::Decorator
    end

    include Representable # include after class methods so Decorator::prepare can't be overwritten by Representable::prepare.

    module InheritModule
      def inherit_module!(parent)
        super # in Representable, calls representable_attrs.inherit!(parent.representable_attrs).

        # puts parent.representable_attrs.inspect
        # new_shit = parent.representable_attrs.clone
        # puts "nw ::::::::::::::::::::: #{new_shit.inspect}"
        __manifest!#(new_shit)

        # representable_attrs.inherit!(new_shit)

        # manifest! # TODO: only manifest new, from parent.
      end

      def __manifest!#(attrs) # one level deep manifesting modules into Decorators.
        # puts "---nw ::::::::::::::::::::: #{attrs.inspect}"
        representable_attrs.each do |cfg| # only definitions.
          next unless mod = cfg.representer_module # only nested decorator.

          next unless mod.is_a?(Module) # FIXME: make this implicit.

  puts "°°°°°°°°°°°°°°°°°° manifesting for #{cfg.name}"
    # here, we can include Decorator features.
          inline_representer = build_inline(nil, [mod]+representable_attrs.features , cfg.name, {}){} # the includer controls what "wraps" the module.
          cfg.merge!(:extend => inline_representer)
        end
      end
    end
    extend InheritModule


    def initialize(represented)
      @represented = represented
    end

  private
    def self.build_inline(base, features, name, options, &block)
      puts "bulding with #{base}"
      Class.new(base || default_inline_class).tap do |decorator|
        decorator.class_eval do # Ruby 1.8.7 wouldn't properly execute the block passed to Class.new!
          include *features
          instance_exec &block
        end
      end
    end
  end
end
