module Representable
  module ParseStrategy
    def property(name, *args, &block)
      if options = args.first and strategy = options[:parse_strategy]
        Sync.call(name, options)
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
  end
end