module Representable
  module ParseStrategy
    def parse_strategies
      {
        :sync                 => Sync,
        :find_or_instantiate  => FindOrInstantiate
      }
    end

    def property(name, *args, &block)
      if options = args.first and strategy = options[:parse_strategy]
        parse_strategies[strategy].call(name, options)
      end

      super
    end

    class Sync
      def self.call(name, options)
        options[:setter]          = lambda { |*| }
        options[:pass_options]    = true
        return options[:instance] = lambda { |fragment, i, options| options.binding.get[i] } if options[:collection]
        options[:instance] = lambda { |fragment, options|  options.binding.get }
      end
    end

    class FindOrInstantiate
      def self.call(name, options)
        options[:instance] = lambda { |fragment, i, *args|
          # FIXME: currently, class can only be a constant name. use Definition#merge!
          # instance_class = options[:class].evaluate(self, *args)
          options[:class].find(fragment["id"]) or options[:class].new
        }
      end
    end
  end
end