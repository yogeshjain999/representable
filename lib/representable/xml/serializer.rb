module Representable
  module XML
    # Functions to create a node tree and render it to XML.
    # Yes - things can be that simple!
    #
    module_function
    def Document()
      document = Node("%", {})
      # document << Node("?xml", version: "1.0") #<?xml version="1.0"?>
      document
    end

    # Create tree functions
    def Node(name, attrs={}, string=nil, children=[])
      [name, attrs, string, children]
    end

    def Append(parent, node)
      parent.last << node
      node
    end

    def Merge(node, attributes)
      node[1].merge!(attributes)
    end

    # Render tree functions
    def Render(arr)
      arr.collect { |(name, attrs, text, children)|
        content = children.any? ? Render(children) : text # TODO: only children argument
        RenderNode(name, attrs, content)
         }.join{""}
    end

    def RenderNode(name, attrs, content)
      %{<#{name}#{RenderAttributes(attrs)}>#{content}</#{name}>}
    end

    def RenderAttributes(attrs)
      attrs.collect { |k, v| %{ #{k}="#{v}"} }.join("")
    end
  end
end
