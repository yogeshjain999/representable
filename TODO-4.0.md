# Decorator

  XML::Binding::Collection.to_xml(represented)
    bindings.each bin.to_xml


  # hat vorteil: [].each{ Collection.to_xml(item) }



# how to?

class CH
  wrap :character
  prpoerty :a


class
  proerty :author, dec: CH

# how to?

* override specific bindings and their logic? e.g. `Namespace#read`
* Extend nested representers, e.g. the namespace prefix, when it gets plugged into composition
* Easier polymorphic representer

# XML

* ditch annoying nokogiri in favor of https://github.com/YorickPeterse/oga

# Parsing

* Let bindings have any "xpath"
* Allow to parse "wildcard" sections where you have no idea about the property names (and attribute names, eg. with links)

# Options

* There should be an easier way to pass a set of options to all nested #to_node decorators.

```ruby
representable_attrs.keys.each do |property|
  options[property.to_sym] = { show_definition: false, namespaces: options[:namespaces] }
end
```
