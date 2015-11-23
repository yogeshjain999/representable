module Representable
  class Populator
    FindOrInstantiate = ->(input, options) {
      binding = options[:binding]

      object_class = binding[:class].(input, options)
      object       = object_class.find_by(id: input["id"]) || object_class.new
      if options[:binding].array?
        # represented.songs[i] = model
        options[:represented].send(binding.getter)[options[:index]] = object
      else
        # represented.song = model
        options[:represented].send(binding.setter, object)
      end

      object
     }

    # pipeline: [StopOnExcluded, AssignName, ReadFragment, StopOnNotFound, OverwriteOnNil, AssignFragment, #<Representable::Function::CreateObject:0x9805a44>, #<Representable::Function::Decorate:0x9805a1c>, Deserialize, Set]

    def self.apply!(options)
      return unless populator = options[:populator]

      options[:parse_pipeline] = ->(input, options) do
        pipeline = Pipeline[*parse_functions] # TODO: AssignFragment
        pipeline = Pipeline::Insert.(pipeline, SetValue, delete: true) # remove the setter function.
        pipeline = Pipeline::Insert.(pipeline, populator, replace: CreateObject::Populator) # let the actual populator do the job.
        # puts pipeline.extend(Representable::Pipeline::Debug).inspect
        pipeline
      end
    end
  end

  FindOrInstantiate = Populator::FindOrInstantiate

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
          lambda { |options| options[:binding].get(options)[options[:index]] } :
          lambda { |options| options[:binding].get(options) }
      end
    end


    # replaces current collection.
    class FindOrInstantiate
      def self.apply!(name, options)
        options[:pass_options] = true
        options[:instance]     = lambda { |options|
          object_class = options[:binding][:class].evaluate(self, options)

          object_class.find_by({id: options[:fragment]["id"]}) or object_class.new
        }
      end
    end
  end
end
