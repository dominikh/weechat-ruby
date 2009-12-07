module Weechat
  class Window
    include Weechat::Pointer
    extend Weechat::Properties

    # A list of all properties that can be retrieved using {#get_string_property}.
    #
    # @private
    @known_string_properties  = [].freeze

    # A list of all properties that can be retrieved using {#get_integer_property}.
    #
    # @private
    @known_integer_properties = %w(win_x win_y win_width win_height win_width_pct
    win_height_pct win_chat_x win_chat_y win_chat_width win_chat_height first_line_displayed scroll scroll_lines_after).freeze

    # A list of all properties that can be set using {#set_property}.
    #
    # @private
    @settable_properties = [].freeze

    # The transformation procedures that get applied to values after
    # they've been received using {#get_property}.
    #
    # @private
    @transformations = {
    }

    # The transformation procedures that get applied to values before they
    # are set by {#set_property}.
    #
    # @private
    @rtransformations = {
    }

    # @private
    @mappings = {

    }

    class << self
      def current
        Window.new(Weechat.current_window)
      end

      # @todo TODO move into own module
      def windows
        windows = []
        Weechat::Infolist.parse("window").each do |window|
          windows << Window.new(window[:pointer])
        end
        windows
      end
      alias_method :all, :windows
    end

    init_properties
  end
end
