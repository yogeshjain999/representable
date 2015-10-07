Representable::Pipeline.class_eval do
  module Function
    class Insert
      def call(arr, func, options)
        arr = arr.dup
        replace!(arr, options[:replace], func)
        arr
      end

    private
      def replace!(arr, old_func, new_func)
        # FIXME: hate the is_a?
        arr.find { |func| old_func.is_a?(Proc)? (func==old_func) : old_func.instance_of?(func.class) } or return

        arr[arr.index(old_func)] = new_func
      end
    end
  end
  Insert = Function::Insert.new
end