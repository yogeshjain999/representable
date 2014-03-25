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
        options[:setter] = lambda { |*| }
        return options[:instance] = lambda { |fragment,i,*| send(name)[i] } if options[:collection]
        options[:instance] = lambda { |fragment,*| send(name) }
      end
    end
  end
end