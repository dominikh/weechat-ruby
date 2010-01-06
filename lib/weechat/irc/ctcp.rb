module Weechat
  module IRC
    class CTCP < Weechat::Modifier
      def initialize(command, &callback)
        super("irc_in_privmsg") do |server, line|
          ret = line
          m = Weechat::IRC::Message.new(line.message)

          if m.ctcp? && (ctcp = m.to_ctcp).ctcp_command == command
             callback.call(server, ctcp)
             ret = nil
          end

          ret
        end
      end
    end
  end
end
