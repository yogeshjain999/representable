module Representable
  module ParseStrategy
    def property(name, *args, &block)
      if options = args.first and strategy = options[:parse_strategy]
        Sync.call(options)
      end

      super
    end

    class Sync
      def self.call(options)
        options[]
      end
    end
  end
end