# NOTE: this might become a separate class, that's why it's in a separate file.
module Representable
  module Binding::Factories
    # i decided not to use polymorphism here for the sake of clarity.
    def collect_for(item_functions)
      return Collect[*item_functions] if array?
      return Collect::Hash[*item_functions] if self[:hash]
      item_functions
    end

    def parse_functions
      [*default_parse_init_functions, *collect_for(default_parse_fragment_functions), *default_post_functions]
    end

    # DISCUSS: StopOnNil, before collect
    def render_functions
      [*default_render_init_functions, *collect_for(default_render_fragment_functions), WriteFragment]
    end

    def default_render_fragment_functions
      functions = []
      functions << SkipRender if self[:skip_render]
      functions << Prepare    if typed?
      functions << Serialize  if representable?
      functions
    end

    def default_render_init_functions
      functions = [Getter]
      functions << Writer if self[:writer]
      functions << RenderFilter if self[:render_filter].any?
      functions << RenderDefault if has_default?
      functions << StopOnSkipable
    end

    def default_parse_init_functions
      functions = [ReadFragment]
      functions << (has_default? ? Default : StopOnNotFound)
      functions << OverwriteOnNil # include StopOnNil if you don't want to erase things.
    end

    def default_parse_fragment_functions
      functions = []
      functions << SkipParse if self[:skip_parse]

      if typed?
        functions += [CreateObject, Prepare]
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