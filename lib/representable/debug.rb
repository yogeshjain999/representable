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

      def representable_mapper(*args)
        super.extend(Mapper)
      end
    end

    module Binding
      def read(doc)
        value = super
        "                #read: #{value.inspect}"
        value
      end

      def evaluate_option(name, *args, &block)
        puts self[name] ?
          "                #evaluate_option: eval #{name}" :
          "                #evaluate_option: ignoring #{name}"
        value = super
        puts "                #evaluate_option: --> #{value} (#{name})"
        value
      end

      def populator
        super.extend(Populator)
      end
    end

    module Populator
      def deserialize(fragment)
        puts "                  Populator#deserialize: #{fragment.inspect}"
        puts "                                       : typed? is false, skipping Deserializer." if ! @binding.typed?
        super
      end

      def deserializer
        super.extend(Deserializer)
      end
    end

    module Deserializer
      def create_object(fragment, *args)
        value = super
          puts "                    Deserializer#create_object: --> #{value.inspect}"
        value
      end
    end

    module Mapper
      def uncompile_fragment(bin, doc)
        bin.extend(Binding)
        puts "              uncompile_fragment: #{bin.name}"
        super
      end
    end
  end
end
