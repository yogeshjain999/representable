module Representable::Represent
  def represent(represented)
    return for_collection.prepare(represented) if represented.is_a?(Array)
    prepare(represented)
  end
end
