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
    def call(context, value, *args)
      inject(value) do |memo, block|
        #

        puts "Pipeline: #{memo.inspect}"
        # res = block.call(memo, *args)
        res = block.call(memo)
        return res if res == Stop # Nil objects here?

        memo[:result] = res
        puts "afteer pipeline: #{res} for #{block}"
        memo
      end # FIXME: aaargh
    end
  end
end


# res, args = block.call(memo, args)
