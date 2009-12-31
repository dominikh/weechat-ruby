module Weechat
  # This class represents a Weechat color.
  #
  # It is created from a color name and saves that name and the color
  # representation.
  class Color
    def self.from_weechat_config(v)
      new(v)
    end

    # @param [String] name Name of the color
    attr_reader :name
    attr_reader :color
    def initialize(name)
      @name = name
    end

    def color
      Weechat.color(name)
    end
    alias_method :to_s, :color
    alias_method :to_str, :color

    def to_weechat_config
      @name
    end

    def ==(other)
      @name == other.name
    end
  end

  class << self
    alias_method :old_color, :color
    def color(name)
      color = Weechat.old_color(name)
      color.empty? ? nil : color
    end
    alias_method :get_color, :color
  end
end
