module Weechat
  module Utilities
    def self.apply_transformation(property, value, transformations)
      transformation = transformations.find {|properties, transformation|
        properties.include?(property.to_sym)
      }

      if transformation
        transformation[1].call(value)
      else
        value
      end
    end
  end
end
