module Weechat
  class Terminal
    # Sets the terminal's title
    def self.title=(value)
      Weechat.window_set_title(value.to_s)
    end
  end
end
