module Representable
  module Debug
    def self.extended(represented)
      represented.extend Representable
    end

    module Representable
      def update_properties_from(doc, options, format)
        puts
        puts "[Deserialize]........."
        puts "[Deserialize] document #{doc.inspect}"
        super
      end

      def create_representation_with(doc, options, format)
        puts
        puts "[Serialize]........."
        puts "[Serialize]"
        super
      end

      def representable_mapper(*args)
        super.extend(Mapper)
      end
    end

    module Binding
      def read(doc)
        value = super
        puts "                #read --> #{value.inspect}"
        value
      end

      def evaluate_option(name, *args, &block)
        puts "=====#{self[name]}" if name ==:prepare
        puts (evaled = self[name]) ?
          "                #evaluate_option [#{name}]: eval!!!" :
          "                #evaluate_option [#{name}]: skipping"
        value = super
        puts "                #evaluate_option [#{name}]: --> #{value}" if evaled
        puts "                #evaluate_option [#{name}]: -->= #{args.first}" if name == :setter
        value
      end

      def populator
        super.extend(Populator)
      end

      def serializer
        super.extend(Serializer)
      end
    end


    module Mapper
      def uncompile_fragment(bin, doc)
        bin.extend(Binding)
        puts "              uncompile_fragment: #{bin.name}"
        super
      end

      def compile_fragment(bin, doc)
        bin.extend(Binding)
        puts "              compile_fragment: #{bin.name}"
        super
      end
    end
  end


  module Pipeline::Debug
    def call(input, options)
      puts "Pipeline#call: #{inspect}"
      puts "               input: #{input.inspect}"
      super
    end

    def evaluate(block, memo, options)
      puts "  Pipeline   :   -> #{_inspect_function(block)} "
      super.tap do |res|
        puts "  Pipeline   :     result: #{res.inspect}"
      end
    end

    def inspect
      collect do |func|
        _inspect_function(func)
      end.join(", ")
    end

    # prints SkipParse instead of <Proc>. i know, i can make this better, but not now.
    def _inspect_function(func)
      return func unless func.is_a?(Proc)
      File.readlines(func.source_location[0])[func.source_location[1]-1].match(/^\s+(\w+)/)[1]
    end
  end
end

