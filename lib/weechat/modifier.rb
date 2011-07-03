module Weechat
  # Class for modifier hooks. These can hook onto events that trigger
  # them, and alter what the event ends up doing.
  # @example
  #   Modifier.new 'weechat_print' do |plugin, buffer, tags, line|
  #    line.message.upcase!
  #    line.to_s
  #   end
  #
  # == List of default weechat and irc hooks
  #   | Plugin  | Modifier                       | Arguments                                                                            | Output                                                                      |
  #   |---------+--------------------------------+--------------------------------------------------------------------------------------+-----------------------------------------------------------------------------|
  #   | charset | charset_decode                 | plugin.buffer_name , any string                                                      | string decoded from charset found for plugin/buffer to UTF-8                |
  #   | charset | charset_encode                 | plugin.buffer_name , any string                                                      | string encoded from UTF-8 to charset found for plugin/buffer                |
  #   | irc     | irc_color_decode               | keep colors boolean, any string                                                      | string with WeeChat color codes, or without color                           |
  #   | irc     | irc_color_encode               | keep colors boolean, any string                                                      | string with IRC color codes, or without color                               |
  #   | irc     | irc_in_xxx (1)                 | server Buffer, content of message received from IRC server (before charset decoding) | new content of message                                                      |
  #   | irc     | irc_in2_xxx (1)                | server Buffer, content of message received from IRC server (after charset decoding)  | new content of message                                                      |
  #   | irc     | irc_out_xxx (1)                | server Buffer, content of message about to be sent to IRC server                     | new content of message                                                      |
  #   | weechat | bar_condition_yyy (2)          | Window                                                                               | Boolean as to whether to display bar                                        |
  #   | weechat | history_add                    | Buffer, input buffer (from user) to add in command history (buffer and global)       | string added to command history                                             |
  #   | weechat | input_text_content             | Buffer , input buffer (from user)                                                    | new content of input buffer                                                 |
  #   | weechat | input_text_display             | Buffer , input buffer (from user), without cursor tag                                | new content of input buffer, for display only (input buffer is not changed) |
  #   | weechat | input_text_display_with_cursor | Buffer , input buffer (from user), with cursor tag                                   | new content of input buffer, for display only (input buffer is not changed) |
  #   | weechat | weechat_print                  | Plugin,Buffer,array of tags, message printed                                         | new message printed                                                         |
  class Modifier < Hook
    def self.inherited(by)
      Hook.inherited(by)
    end

    attr_reader :modifier
    # creates a modifier hook.
    # @param [String] modifier The name of the modifier. Can contain
    #   wildcards (*) at the beginning and end to match multiple modifier hooks
    # @yield (*args) The block that is called for the modifier hook
    # @yieldparam [Array] args The arguments for the modifier hook
    # @yieldreturn The result for the modifier, depends on the modifier being hooked to
    def initialize(modifier, &callback)
      super
      @modifier = modifier.to_s
      @callback         = Callback.new(callback)
      @ptr              = Weechat.hook_modifier(modifier, "modifier_callback", id.to_s)
    end

    alias_method :exec, :call

    class << self
      def call(modifier, data, string)
        Weechat.hook_modifier_exec(modifier.to_s, data.to_s, string.to_s)
      end
      alias_method :exec, :call
    end
  end

  module Modifiers
    class Print < Weechat::Modifier
      class PrintModifierCallback < Weechat::Callback
        def call(plugin, buffer, tags, line)
          begin
            ret = @callback.call(plugin, buffer, tags, line)
          rescue => e
            Weechat::Utilities.format_exception(e)
            return line
          end
          return ret
        end
      end # PrintModifierCallback

      def initialize(&callback)
        super("weechat_print", &callback)
        @callback = PrintModifierCallback.new(callback)
      end
    end # Print

    Mappings = {
      'weechat_print' => Print,
    }
  end # Modifiers
end
