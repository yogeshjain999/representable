module Representable
  Pipeline.class_eval do # FIXME: this doesn't define Function in Pipeline.
    module Function
      class Insert
        def call(arr, func, options)
          arr = arr.dup
          replace!(arr, options[:replace], func)
          arr
        end

      private
        def replace!(arr, old_func, new_func)
          arr.each_with_index { |func, index|
            if func.is_a?(Collect)
              arr[index] = Collect[*Pipeline::Insert.(func, new_func, replace: old_func)]
            end

            arr[index] = new_func if old_func.is_a?(Proc)? (func==old_func) : old_func.instance_of?(func.class)
          }
        end
      end
    end
  end

  Pipeline::Insert = Function::Insert.new
end