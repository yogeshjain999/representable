
module Representable
  # AssignDoc = ->(input, options) { options[:doc] = input }

  Getter = ->(input, options) do
    binding = options[:binding]

    binding.evaluate_option_with_deprecation(:getter, input, options, :user_options) do # TODO: should we have binding.get doing the block content?
      binding.send(:exec_context).send(binding.getter)
    end
  end

  # FIXME: we don't need to evaluate here but can run the option straight away, because
  # we only add Writer when :writer is present!
  Writer = ->(input, options) do
    options[:binding].evaluate_option_with_deprecation(:writer, input, options, :doc, :user_options) do
      return input
    end
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
    options[:binding].render_filter(input, options[:doc]) # FIXME.
  end

  SkipRender = ->(input, options) do
    options[:binding].evaluate_option_with_deprecation(:skip_render, input, options, :input, :user_options) ? Pipeline::Stop : input
  end

  # FIXME: Collect always assigns :fragment as input. how are we gonna handle that?
  Serialize = ->(input, options) do
    binding = options[:binding]

    return if input.nil?

    binding.evaluate_option(:serialize, input) do
      input.send(binding.serialize_method, binding.user_options) # FIXME: what options here?
    end
  end


  WriteFragment = ->(input, options) { options[:binding].write(options[:doc], input) }
end