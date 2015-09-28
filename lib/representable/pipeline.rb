module Representable
  # Allows to implement a pipeline of filters where a value gets passed in and the result gets
  # passed to the next callable object.
  #
  # Note: this is still experimental.
  class Pipeline < Array
    include Uber::Callable
    # include Representable::Cloneable

    Stop = nil

    def call(context, value, *args)
      inject(value) do |memo, block|
        return memo if memo == Stop # Nil objects here?
        block.call(memo, *args)
      end
    end
  end
end
