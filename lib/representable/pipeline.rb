module Representable
  # Allows to implement a pipeline of filters where a value gets passed in and the result gets
  # passed to the next callable object.
  #
  # Note: this is still experimental.
  class Pipeline < Array
    include Uber::Callable
    # include Representable::Cloneable

    Stop = Class.new

    # DISCUSS: should we use different pipelines for render_filter, etc.?
    def call(value, *args)
      inject(value) do |memo, block|
        res = block.call(memo)
        return Stop if res == Stop # Nil objects here?

        memo[:result] = res
        memo
      end[:result] # FIXME: aaargh
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

        puts "Pipeline: #{memo.inspect}"
        # res = block.call(memo, *args)
       block.call(memo, *args)
        # return res if res == Stop # Nil objects here?

      end
    end
  end
end


# res, args = block.call(memo, args)
