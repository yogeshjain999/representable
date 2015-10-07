# NOTE: this might become a separate class, that's why it's in a separate file.
module Representable
  module Binding::Factories
  def parse_functions
    return self[:parse_pipeline].() if self[:parse_pipeline] # untested.

    if array?
      return [*default_init_functions, Collect[*default_parse_fragment_functions], *default_post_functions]
    end
    if self[:hash] # FIXME: fuckin' merge with array?
      return [*default_init_functions, Collect::Hash[*default_parse_fragment_functions], *default_post_functions]
    end

    [*default_init_functions, *default_parse_fragment_functions, *default_post_functions]
  end


  def render_functions
    # return self[:parse_pipelinerender_pipeline].() if self[:render_pipeline] # untested. # FIXME.

    if array?
      return [*default_render_init_functions, StopOnSkipable, StopOnNil, Collect[*default_render_fragment_functions], WriteFragment]
    end

    if self[:hash]
      return [*default_render_init_functions, StopOnSkipable, StopOnNil, Collect::Hash[*default_render_fragment_functions], WriteFragment]
    end

    [*default_render_init_functions, RenderDefault, StopOnSkipable, *default_render_fragment_functions, WriteFragment]
  end

  def default_render_fragment_functions
    functions = []

    functions << SkipRender if self[:skip_render]

    if typed?
      functions << Prepare
    end
    functions << Serialize if representable?

    functions
  end
  def default_render_init_functions
    functions = [Getter]
      functions << Writer if self[:writer]
      functions << RenderFilter if self[:render_filter].any?
      functions
    end

    # TODO: move to Pipeline::Builder
    def default_init_functions
      functions = [ReadFragment, has_default? ? Default : StopOnNotFound]
      functions << OverwriteOnNil # include StopOnNil if you don't want to erase things.
      functions
    end

    def default_parse_fragment_functions
      functions = [] # TODO: why do we always need that?
      functions << SkipParse if self[:skip_parse]

      if typed?
        functions += [CreateObject, Prepare]
        # TODO: Insert InputToFragment
        functions << Deserialize if representable?
      end

      functions
    end

    def default_post_functions
      funcs = []
      funcs << ParseFilter if self[:parse_filter].any?
      funcs << Setter
    end
  end
end