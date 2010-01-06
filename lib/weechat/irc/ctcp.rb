module Weechat
  module IRC
    class CTCP < Message
      attr_reader :receiver
      attr_reader :ctcp_command
      attr_reader :ctcp_param

      def initialize(*args)
        super
        @receiver = @params.first
        parts = @params.last[1..-2].split(" ")
        @ctcp_command = parts.first
        @ctcp_param = parts[1..-1].join(" ")
      end

      def ctcp?
        true
      end
    end
  end
end
