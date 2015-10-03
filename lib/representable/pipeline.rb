module Representable
  # Allows to implement a pipeline of filters where a value gets passed in and the result gets
  # passed to the next callable object.
  class Pipeline < Array
    include Uber::Callable
    # include Representable::Cloneable

    Stop = Class.new

    # DISCUSS: should we use different pipelines for render_filter, etc.?
    def call(options)
      inject(options) do |memo, block|
        res = evaluate(block, memo)
        return Stop if res == Stop # Nil objects here?

        memo[:result] = res
        memo
      end[:result] # FIXME: aaargh
    end

  private
    def evaluate(block, memo)
      block.call(memo)
    end


    module Debug
      def call(options)
        puts "Pipeline#call: #{inspect}"
        super
      end

      def evaluate(block, memo)
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

  class ShitblaaPipeline < Array
    include Uber::Callable
    # include Representable::Cloneable

    Stop = Class.new

    # DISCUSS: should we use different pipelines for render_filter, etc.?
    def call(context, value, *args)
      inject(value) do |memo, block|
        #

        puts "xPipeline: #{memo.inspect}"
        # res = block.call(memo, *args)
       block.call(memo, *args)
        # return res if res == Stop # Nil objects here?

      end
    end
  end
end


# res, args = block.call(memo, args)
