module Weechat
  module Utilities
    def self.apply_transformation(property, value, transformations)
      transformation = transformations.find {|properties, transformation|
        properties.include?(property.to_sym)
      }[1]
      transformation.call(value)
    end
  end
end
