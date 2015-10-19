module Representable
  class Populator
    NoOp = ->(input, options) { input }

    FindOrInstantiate = ->(input, options) {
      AssignFragment.(input, options)

      object_class = options[:binding][:class].(input, options)
      options[:represented].songs[options[:index]] = object_class.find_by({id: input["id"]}) || object_class.new
     }

    def self.apply!(options)
      return unless strategy = options[:populator]

      options[:parse_pipeline] = ->(input, options) do
        pipeline = [*parse_functions] # AssignFragment
        pipeline = Pipeline[*Pipeline::Insert.(pipeline, NoOp, replace: Set)]
        pipeline = Pipeline[*Pipeline::Insert.(pipeline, FindOrInstantiate, replace: CreateObject)].extend(Pipeline::Debug)
      end
    end
  end
  # Parse strategies are just a combination of representable's options. They save you from memoizing the
  # necessary parameters.
  #
  # Feel free to contribute your strategy if you think it's worth sharing!
  class ParseStrategy
    def self.apply!(options)
      return unless strategy = options[:parse_strategy]

      warn "[Representable] :parse_strategy is deprecated. Please use a populator."

      strategy = :proc if strategy.is_a?(::Proc)

      parse_strategies[strategy].apply!(name, options)
    end

    def self.parse_strategies
      {
        :sync                 => Sync,
        :find_or_instantiate  => FindOrInstantiate,
        :proc                 => Proc
      }
    end


    # Using a lambda as parse_strategy does not set the parsed property for you.
    class Proc
      def self.apply!(name, options)
        options[:setter]       = lambda { |*| }
        options[:pass_options] = true
        options[:instance]     = options[:parse_strategy]
      end
    end


    class Sync
      def self.apply!(name, options)
        options[:setter]       = lambda { |*args| }
        options[:pass_options] = true
        options[:instance]     = options[:collection] ?
          lambda { |fragment, i, options| options.binding.get(represented: options.represented)[i] } :
          lambda { |fragment, options|    options.binding.get(represented: options.represented) }
      end
    end


    # replaces current collection.
    class FindOrInstantiate
      def self.apply!(name, options)
        options[:pass_options] = true
        options[:instance]     = lambda { |fragment, *args|
          args = args.last # TODO: don't pass i as separate block parameter but in Options.
          object_class = args.binding[:class].evaluate(self, fragment, args)

          object_class.find_by({id: fragment["id"]}) or object_class.new
        }
      end
    end
  end
end
