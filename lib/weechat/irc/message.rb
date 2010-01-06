module Weechat
  module IRC
    class Message
      attr_reader :prefix, :command, :params

      def initialize(line)
        @line = line

        parts = line.split(' ')

        if parts[0][0..0] == ':'
          @prefix = Prefix.new(parts.shift[1..-1])
        else
          @prefix = ''
        end

        @command = parts.shift

        @params = []
        until parts.empty? do
          if parts[0][0..0] == ':'
            @params << parts.join(' ')[1..-1]
            break
          else
            @params << parts.shift
          end
        end
      end

      def ctcp?
        @params.size == 2 && @params.last[0..0] == "\x01" && @params.last[-1..-1] == "\x01"
      end

      def to_ctcp
        raise "not a ctcp" unless ctcp?
        Weechat::IRC::Message::CTCP.new(@line)
      end

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
      end # CTCP
    end # Message
  end
end
