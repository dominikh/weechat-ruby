module Weechat
  class Input
    def initialize(buffer)
      @buffer = buffer
    end

    # Returns the current content of the input line.
    def to_s
      @buffer.get_property("input")
    end
    alias_method :text, :to_s
    alias_method :content, :to_s

    # Sets the content of the input line.
    def text=(val)
      @buffer.set_property("input", val)
    end
    alias_method :content=, "text="

    def size
      @buffer.input_buffer_size
    end

    def pos
      @buffer.input_buffer_pos
    end

    def get_unknown_commands=(val)
      @buffer.set_property("input_get_unknown_commands", val)
    end

    def get_unknown_commands?
      @buffer.get_property("input_get_unknown_commands")
    end
    alias_method :get_unknown_commands, :get_unknown_commands?
  end
end
