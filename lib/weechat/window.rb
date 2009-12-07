module Weechat
  # == Gettable properties
  #
  # [x]                     X position of the window in the terminal
  # [y]                     Y position of the window in the terminal
  # [width]                 Width of the window
  # [height]                Height of the window
  # [width_pct]             Width relative to the one of the parent window (0..100%)
  # [height_pct]            Height relative to the one of the parent window (0..100%)
  # [first_line_displayed?] True if the first line of the displayed buffer is displayed on the screen
  # [scrolling?]            True if the window is currently being scrolled
  # [scrolling_lines]       Number of lines that are not being displayed (in the bottom direction)
  #
  # == The chat area
  #
  # See {Window::Chat}
  class Window
    # == Gettable properties
    #
    # [x]      X position of the chat area
    # [y]      Y position of the chat area
    # [width]  Width of the chat area
    # [height] Height of the chat area
    class Chat
      %w(x y width height).each do |prop|
        define_method(prop) do
          @window.get_property("win_chat_#{prop}")
        end
      end

      def initialize(window)
        @window = window
      end
    end
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
    win_height_pct win_chat_x win_chat_y win_chat_width win_chat_height first_line_displayed
    scroll scroll_lines_after).freeze

    # A list of all properties that can be set using {#set_property}.
    #
    # @private
    @settable_properties = [].freeze

    # The transformation procedures that get applied to values after
    # they've been received using {#get_property}.
    #
    # @private
    @transformations = {
      [:first_line_displayed, :scroll] => lambda {|v| Weechat.integer_to_bool(v) },
      [:buffer] => lambda {|v| Buffer.new(v) },
    }.freeze

    # The transformation procedures that get applied to values before they
    # are set by {#set_property}.
    #
    # @private
    @rtransformations = {
    }.freeze

    # @private
    # @known_integer_properties = %w(win_x win_y win_width win_height win_width_pct
    # win_height_pct win_chat_x win_chat_y win_chat_width win_chat_height first_line_displayed scroll scroll_lines_after).freeze
    @mappings = {
      :x => :win_x,
      :y => :win_y,
      :width => :win_width,
      :height => :win_height,
      :width_pct => :win_width_pct,
      :height_pct => :win_height_pct,
      :chat_x => :win_chat_x,
      :chat_y => :win_chat_y,
      :chat_width => :win_chat_width,
      :chat_height => :win_chat_height,
      :first_line_displayed? => :first_line_displayed,
      :scrolling? => :scroll,
      :scrolling_lines => :scroll_lines_after
    }.freeze

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

    attr_reader :chat
    def initialize(*args)
      super
      @chat = Chat.new(self)
    end
  end
end
