module Representable
  Getter = ->(input, options) do
    binding = options[:binding]

    binding.evaluate_option(:getter, input, options) do # TODO: should we have binding.get doing the block content?
      binding.send(:exec_context).send(binding.getter)
    end
  end

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

  Serialize = ->(input, options) do
    binding = options[:binding]

    return if input.nil?

    binding.evaluate_option(:serialize, input, options) do
      input.send(binding.serialize_method, binding.user_options) # FIXME: what options here?
    end
  end

  WriteFragment = ->(input, options) { options[:binding].write(options[:doc], input) }
end