module Weechat
  module Utilities
    def self.apply_transformation(property, value, transformations)
      transformations.each do |properties, transformation|
        if properties.include?(property.to_sym)
          value = transformation.call(value)
          break
        end
      end
      value
    end
  end
end
