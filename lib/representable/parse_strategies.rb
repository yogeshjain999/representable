module Representable
  class ParseStrategy
    def self.apply!(options)
      return unless strategy = options[:parse_strategy]

      parse_strategies[strategy].apply!(name, options)
    end

    def self.parse_strategies
      {
        :sync                 => Sync,
        :find_or_instantiate  => FindOrInstantiate,
      }
    end


    class Sync
      def self.apply!(name, options)
        options[:setter]          = lambda { |*| }
        options[:pass_options]    = true
        options[:instance] = options[:collection] ?
          lambda { |fragment, i, options| options.binding.get[i] } :
          lambda { |fragment, options|  options.binding.get }
      end
    end


    class FindOrInstantiate
      def self.apply!(name, options)
        options[:instance] = lambda { |fragment, i, *args|
          # FIXME: currently, class can only be a constant name. use Definition#merge!
          # instance_class = options[:class].evaluate(self, *args)
          options[:class].find(fragment["id"]) or options[:class].new
        }
      end
    end
  end
end