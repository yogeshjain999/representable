module Representable::XML
  # Experimental!
  # Best explanation so far: http://books.xmlschemata.org/relaxng/relax-CHP-11-SECT-1.html
  module Namespace
    def self.included(includer)
      includer.extend(DSL)
    end

    module DSL
      def namespace(namespace)
        representable_attrs.options[:local_namespace] = namespace
        representable_attrs.options[:namespace_mappings] ||= {}
        representable_attrs.options[:namespace_mappings][namespace] = nil # this might get overwritten via #namespace_def later.
      end

      def namespace_def(mapping)
        namespace_defs.merge!(mapping.invert)
      end

      # :private:
      def namespace_defs
        representable_attrs.options[:namespace_mappings] ||= {}
      end

      def property(name, options={})
        uri = representable_attrs.options[:local_namespace] # per default, a property belongs to the local namespace.
        options[:namespace] ||= uri # don't override if already set.

        # options[:namespace_defs] = namespace_defs

        # a nested representer is automatically assigned "its" local namespace. It's like saying
        #   property :author, namespace: "http://ns/author" do ... end

        super.tap do |dfn|
          if dfn.typed? # FIXME: ouch, this should be doable with property's API to hook into the creation process.
            dfn.merge!( namespace: dfn.representer_module.representable_attrs.options[:local_namespace] )

            update_namespace_defs!(namespace_defs)
          end
        end
      end

      # :private:
      # super ugly hack
      # recursively injects the namespace_defs into all representers of this tree. will be done better in 4.0.
      def update_namespace_defs!(namespace_defs)
        representable_attrs.each do |dfn|
          dfn.merge!(namespace_defs: namespace_defs) # this only helps with scalars

          if dfn.typed?
            representer = Class.new(dfn.representer_module) # don't pollute classes.
            representer.update_namespace_defs!(namespace_defs)
            dfn.merge!(extend: representer)
          end
        end
      end
    end

    module AsWithNamespace
      def write(doc, fragment, as)
        uri    = self[:namespace] # this is generic behavior and per property
        # prefix = options[:options][:namespaces][uri]
        prefix = self[:namespace_defs][uri]
        as     = Namespace::Namespaced(prefix, as)

        super(doc, fragment, as)
      end

      # FIXME: this is shit, the NestedOptions is executed too late here!
      def read(fragment, options)
        puts "@@@@@--> #{options[:options].inspect}"
        # if namespace = options[:options][:namespace] # this is generic behavior and per property
          # this is for song and band, because the options are done too late.
        if options[:options][self[:name].to_sym] and namespace =   options[:options][self[:name].to_sym][:namespace] # this is generic behavior and per property
          options[:as] = "#{namespace}:#{options[:as]}"
           # raise options[:as].inspect
        elsif namespace = options[:options][:namespace] # this is generic behavior and per property
          options[:as] = "#{namespace}:#{options[:as]}"
        end

        super
      end
    end

    def from_node(node, options={})
      options_for_nested_namespaced_representers!(representable_attrs.options[:registered_namespaces], options)
      # options[:song] = { namespace: :nsSong }

      super
    end

    def to_xml(options={})
      super( options.merge(namespaces: self.class.namespace_defs) )
    end


    def to_node(options={})
      local_uri = representable_attrs.options[:local_namespace] # every decorator MUST have a local namespace.
      prefix    = options[:namespaces][local_uri]

      # if namespace = options[:namespace] # this is generic behavior and per property
      root_tag = [prefix, representation_wrap(options)].compact.join(":")


      options = { wrap: root_tag }.merge(options)

      # TODO: there should be an easier way to pass a set of options to all nested #to_node decorators.
      representable_attrs.keys.each do |property|
        options[property.to_sym] = { show_definition: false, namespaces: options[:namespaces] }
      end

      super(options).tap do |node|
        add_namespace_definitions!(node, self.class.namespace_defs) unless options[:show_definition] == false
      end
    end

    # "Physically" add `xmlns` attributes to `node`.
    def add_namespace_definitions!(node, namespaces)
      namespaces.each do |uri, prefix|
        # Nokogiri's API sucks hard here.
        prefix.nil? ?
          node.default_namespace = uri :
          node.add_namespace_definition(prefix.to_s, uri)
      end
    end

    def self.Namespaced(prefix, name)
      [ prefix, name ].compact.join(":")
    end


    # FIXME: this is a PoC, we need a better API to inject code.
    def representable_map(options, format)
      super.tap do |map|
        map.each { |bin| bin.extend(AsWithNamespace) unless bin.is_a?(Binding::Attribute) }
      end
    end
  end
end
