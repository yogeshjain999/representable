module Representable::Binding::Deprecation
  # Options instance gets passed to lambdas when pass_options: true.
  # This is considered the new standard way and should be used everywhere for forward-compat.
  Options = Struct.new(:binding, :user_options, :represented, :decorator)

  def evaluate_option(name, input=nil, options={}, &block)
    return evaluate_option_with_deprecation(name, input, options, :user_options, &block) if name==:as
    return evaluate_option_with_deprecation(name, input, options, :user_options, &block) if name==:if
    return evaluate_option_with_deprecation(name, input, options, :user_options, &block) if name==:getter
    return evaluate_option_with_deprecation(name, input, options, :doc, :user_options, &block) if name==:writer
    return evaluate_option_with_deprecation(name, input, options, :input, :user_options, &block) if name==:skip_render
    return evaluate_option_with_deprecation(name, input, options, :input, :user_options, &block) if name==:skip_parse
    return evaluate_option_with_deprecation(name, input, options, :input, :user_options, &block) if name==:serialize
    return evaluate_option_with_deprecation(name, input, options, :doc, :user_options, &block) if name==:reader
    return evaluate_option_with_deprecation(name, input, options, :input, :index, :user_options, &block) if name==:instance
    return evaluate_option_with_deprecation(name, input, options, :input, :index, :user_options, &block) if name==:class
    return evaluate_option_with_deprecation(name, input, options, :input, :fragment, :user_options, &block) if name==:deserialize
    return evaluate_option_with_deprecation(name, input, options, :input, :user_options, &block) if name==:prepare
    return evaluate_option_with_deprecation(name, input, options, :input, :user_options, &block) if name==:extend
    return evaluate_option_with_deprecation(name, input, options, :input, :user_options, &block) if name==:setter
    super(name, input, &block)
  end

private
  def evaluate_option_with_deprecation(name, input, options, *positional_arguments)
      unless proc = @definition[name]
        return yield if block_given?
        return
      end


      options[:input] = input # DISCUSS: can we save time here?


      __options = if self[:pass_options]
        warn %{[Representable] The :pass_options option is deprecated. Please access environment objects via options[:binding].
  Learn more here: http://trailblazerb.org/gems/representable/upgrading-guide.html#pass-options}
        Options.new(self, user_options, represented, parent_decorator)
      else
        user_options
      end
      options[:user_options] = __options # TODO: always make this user_options in Representable 3.0.


      if proc.send(:proc?) or proc.send(:method?)
        arity = proc.instance_variable_get(:@value).arity if proc.send(:proc?)
        arity = exec_context.method(proc.instance_variable_get(:@value)).arity if proc.send(:method?)
        if arity  != 1 or name==:getter or name==:if or name==:as
          warn %{[Representable] Positional arguments for `:#{name}` are deprecated. Please use options or keyword arguments.
  #{name}: ->(options) { options[:#{positional_arguments.join(" | :")}] } or
  #{name}: ->(#{positional_arguments.join(":, ")}:) {  }
  Learn more here: http://trailblazerb.org/gems/representable/upgrading-guide.html#positional-arguments
  }
          deprecated_args = []
          positional_arguments.each do |arg|
            next if arg == :index && options[:index].nil?
            deprecated_args << __options  and next if arg == :user_options# either hash or Options object.
            deprecated_args << options[arg]
          end

          return proc.(exec_context, *deprecated_args)
        end
      end

      proc.(name, options)
    end
end