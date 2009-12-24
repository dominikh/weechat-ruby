module Weechat
  # == Gettable properties
  #
  # [buffer]                The buffer currently shown in the window
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

      attr_reader :window
      protected :window

      def initialize(window)
        @window = window
      end

      def ==(other)
        @window == other.window
      end
      alias_method :eql?, "=="
      alias_method :equal?, "=="
    end
    include Weechat::Pointer
    extend Weechat::Properties

    # A list of all properties that can be retrieved using {#get_integer_property}.
    #
    # @private
    @known_integer_properties = %w(win_x win_y win_width win_height win_width_pct
    win_height_pct first_line_displayed
    scroll scroll_lines_after).freeze

    # The transformation procedures that get applied to values after
    # they've been received using {#get_property}.
    #
    # @private
    @transformations = {
      [:first_line_displayed, :scroll] => lambda {|v| Weechat.integer_to_bool(v) },
      [:buffer] => lambda {|v| Buffer.from_ptr(v) },
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
      :first_line_displayed? => :first_line_displayed,
      :scrolling? => :scroll,
      :scrolling_lines => :scroll_lines_after
    }.freeze

    class << self
      def current
        Window.from_ptr(Weechat.current_window)
      end

      # @todo TODO move into own module
      def windows
        windows = []
        Weechat::Infolist.parse("window").each do |window|
          windows << Window.from_ptr(window[:pointer])
        end
        windows
      end
      alias_method :all, :windows

      def from_ptr(*args)
        o = super
        o.instance_variable_set(:@chat, Chat.new(o))
      end
    end

    init_properties

    attr_reader :chat
  end
end
