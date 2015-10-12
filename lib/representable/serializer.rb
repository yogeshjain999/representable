module Representable
  Getter = ->(input, options) do
    options[:binding].evaluate_option(:getter, input, options) do # TODO: should we have binding.get doing the block content?
      Get.(input, options)
    end
  end

  Get = ->(input, options) { options[:binding].send(:exec_context).send(options[:binding].getter) }

  Writer = ->(input, options) do
    options[:binding].evaluate_option(:writer, input, options)
    Pipeline::Stop
  end

  # TODO: evaluate this, if we need this.
  RenderDefault = ->(input, options) do
    binding = options[:binding]

    binding.skipable_empty_value?(input) ? binding[:default] : input
  end

  StopOnSkipable = ->(input, options) do
    options[:binding].send(:skipable_empty_value?, input) ? Pipeline::Stop : input
  end

  RenderFilter = ->(input, options) do
    options[:binding][:render_filter].(input, options)
  end

  SkipRender = ->(input, options) do
    options[:binding].evaluate_option(:skip_render, input, options) ? Pipeline::Stop : input
  end

  Serializer = ->(input, options) do
    return if input.nil? # DISCUSS: how can we prevent that?

    options[:binding].evaluate_option(:serialize, input, options)
  end

  Serialize = ->(input, options) do
    return if input.nil? # DISCUSS: how can we prevent that?
    binding, user_options = options[:binding], options[:user_options]

    user_options = user_options.merge(wrap: binding[:wrap]) unless binding[:wrap].nil? # DISCUSS: can we leave that here?

    input.send(binding.serialize_method, user_options)
  end

  WriteFragment = ->(input, options) { options[:binding].write(options[:doc], input, As.(input, options)) }

  As = ->(input, options) { options[:binding].evaluate_option(:as, input, options) }
end