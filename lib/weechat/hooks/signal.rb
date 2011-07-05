module Weechat

  module Hooks
    # A hook to a weechat signal.
    # @example
    #   Hooks::Signal.new('buffer_switch') do |signal, buffer|
    #     puts buffer.name
    #   end
    #
    # == List of default signals
    #
    #    | Plugin  | Signal                  | Arguments                                 | Description                                                                                     |
    #    |---------+-------------------------+-------------------------------------------+-------------------------------------------------------------------------------------------------|
    #    | irc     | xxx,irc_in_yyy (1)      | IRC::Message                              | irc message from server (before irc plugin uses it, signal sent only if message is not ignored) |
    #    | irc     | xxx,irc_in2_yyy (1)     | IRC::Message                              | irc message from server (after irc plugin uses it, signal sent only if message is not ignored)  |
    #    | irc     | xxx,irc_raw_in_yyy (1)  | IRC::Message                              | irc message from server (before irc plugin uses it, signal sent even if message is ignored)     |
    #    | irc     | xxx,irc_raw_in2_yyy (1) | IRC::Message                              | irc message from server (after irc plugin uses it, signal sent even if message is ignored)      |
    #    | irc     | xxx,irc_out_yyy (1)     | IRC::Message                              | irc message sent to server                                                                      |
    #    | irc     | xxx,irc_outtags_yyy (1) | string: tags + ";" + message              | tags + irc message sent to server                                                               |
    #    | irc     | irc_ctcp                | IRC::Message                              | CTCP received                                                                                   |
    #    | irc     | irc_dcc                 | IRC::Message                              | new DCC                                                                                         |
    #    | irc     | irc_pv                  | IRC::Message                              | private message received                                                                        |
    #    | irc     | irc_channel_opened      | Buffer                                    | channel opened                                                                                  |
    #    | irc     | irc_pv_opened           | Buffer                                    | private opened                                                                                  |
    #    | irc     | irc_server_connecting   | string: server name                       | connecting to server                                                                            |
    #    | irc     | irc_server_connected    | string: server name                       | connected to server                                                                             |
    #    | irc     | irc_server_disconnected | string: server name                       | disconnected from server                                                                        |
    #    | irc     | irc_ignore_removing     | pointer: ignore                           | removing ignore                                                                                 |
    #    | irc     | irc_ignore_removed      | -                                         | ignore removed                                                                                  |
    #    | logger  | logger_start            | Buffer                                    | start logging for buffer                                                                        |
    #    | logger  | logger_stop             | Buffer                                    | stop logging for buffer                                                                         |
    #    | logger  | logger_backlog          | Buffer                                    | display backlog for buffer                                                                      |
    #    | weechat | buffer_closing          | Buffer                                    | closing buffer                                                                                  |
    #    | weechat | buffer_closed           | Buffer                                    | buffer closed                                                                                   |
    #    | weechat | buffer_lines_hidden     | Buffer                                    | lines hidden in buffer                                                                          |
    #    | weechat | buffer_localvar_added   | Buffer                                    | local variable has been added                                                                   |
    #    | weechat | buffer_localvar_changed | Buffer                                    | local variable has changed                                                                      |
    #    | weechat | buffer_localvar_removed | Buffer                                    | local variable has been removed                                                                 |
    #    | weechat | buffer_moved            | Buffer                                    | buffer moved                                                                                    |
    #    | weechat | buffer_opened           | Buffer                                    | buffer opened                                                                                   |
    #    | weechat | buffer_renamed          | Buffer                                    | buffer renamed                                                                                  |
    #    | weechat | buffer_switch           | Buffer                                    | switching buffer                                                                                |
    #    | weechat | buffer_title_changed    | Buffer                                    | title of buffer changed                                                                         |
    #    | weechat | buffer_type_changed     | Buffer                                    | type of buffer changed                                                                          |
    #    | weechat | day_changed             | string: new date, format: "2010-01-31"    | day of system date has changed                                                                  |
    #    | weechat | debug_dump              | string: plugin name                       | dump request                                                                                    |
    #    | weechat | filter_added            | pointer: filter                           | filter added                                                                                    |
    #    | weechat | filter_removing         | pointer: filter                           | removing filter                                                                                 |
    #    | weechat | filter_removed          | -                                         | filter added                                                                                    |
    #    | weechat | filter_enabled          | -                                         | filters enabled                                                                                 |
    #    | weechat | filter_disabled         | -                                         | filters disabled                                                                                |
    #    | weechat | hotlist_changed         | -                                         | hotlist changed                                                                                 |
    #    | weechat | input_paste_pending     | -                                         | paste pending                                                                                   |
    #    | weechat | input_search            | -                                         | text search in buffer                                                                           |
    #    | weechat | input_text_changed      | -                                         | input text changed                                                                              |
    #    | weechat | input_text_cursor_moved | -                                         | input text cursor moved                                                                         |
    #    | weechat | key_pressed             | string: key pressed                       | key pressed                                                                                     |
    #    | weechat | nicklist_group_added    | string: buffer pointer + "," + group name | group added in nicklist                                                                         |
    #    | weechat | nicklist_group_removed  | string: buffer pointer + "," + group name | group removed from nicklist                                                                     |
    #    | weechat | nicklist_nick_added     | string: buffer pointer + "," + nick name  | nick added in nicklist                                                                          |
    #    | weechat | nicklist_nick_removed   | string: buffer pointer + "," + nick name  | nick removed from nicklist                                                                      |
    #    | weechat | partial_completion      | -                                         | partial completion happened                                                                     |
    #    | weechat | quit                    | string: arguments for /quit               | command /quit issued by user                                                                    |
    #    | weechat | upgrade                 | -                                         | command /upgrade issued by user                                                                 |
    #    | weechat | upgrade_ended           | -                                         | end of upgrade process (command /upgrade)                                                       |
    #    | weechat | weechat_highlight       | string: message with prefix               | highlight happened                                                                              |
    #    | weechat | weechat_pv              | string: message with prefix               | private message displayed                                                                       |
    #    | weechat | window_scrolled         | pointer: window                           | scroll in window                                                                                |
    #    | weechat | window_unzooming        | Window (current)                          | unzooming window                                                                                |
    #    | weechat | window_unzoomed         | Window (current)                          | window unzoomed                                                                                 |
    #    | weechat | window_zooming          | Window (current)                          | zomming window                                                                                  |
    #    | weechat | window_zoomed           | Window (current)                          | window zoomed                                                                                   |
    #    | xfer    | xfer_add                | pointer: infolist with xfer info          | new xfer                                                                                        |
    #    | xfer    | xfer_send_ready         | pointer: infolist with xfer info          | xfer ready                                                                                      |
    #    | xfer    | xfer_accept_resume      | pointer: infolist with xfer info          | xfer accepts resume (send)                                                                      |
    #    | xfer    | xfer_send_accept_resume | pointer: infolist with xfer info          | xfer accepts resume (send)                                                                      |
    #    | xfer    | xfer_start_resume       | pointer: infolist with xfer info          | start resume                                                                                    |
    #    | xfer    | xfer_resume_ready       | pointer: infolist with xfer info          | xfer resume ready                                                                               |
    #    | xfer    | xfer_ended              | pointer: infolist with xfer info          | xfer has ended                                                                                  |
    #
    class Signal < Hook
      # Create a new signal hook.
      # @param [String] signal The signal to connect to. The signal can contain
      #   wildcards (*) at the start and the end to match multiple signals
      # @yield(signal_name, *args) The block that is called when the signal
      #   occurs.
      # @yieldparam [String] signal_name The name of the signal that trigger
      #   the signal. Useful when using wildcards to match the signal
      # @yieldparam [Array] args Extra arguments passed by the signal
      #   to the hook
      #
      # See the class documentation for a list of the default weechat and irc
      # signals that can be hooked to.
      def initialize(signal='*', &callback)
        super
        @callback = EvaluatedCallback.new(callback)
        @ptr      = Weechat.hook_signal(signal, "signal_callback", id.to_s)
      end

      class << self
        def send(signal, type, data)
          Weechat.hook_signal_send(signal.to_s, type.to_s, data.to_s)
        end
        alias_method :exec, :send
      end
    end
  end
end
