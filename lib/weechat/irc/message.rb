module Weechat
  module IRC
    class Message
      attr_reader :prefix, :command, :params


      # parses an irc message line, and returns an appropriate subclass of IRC::Message
      # represent the message.
      # @param [String] irc_message The irc message to parse
      # @return [IRC::Message] Either the base message class or a specific message base
      #   class if one exists. Currently the only one that exists is PRIVMSG
      # TODO make more subclasses
      def self.parse_message(irc_message)
        # todo this is a bit hacky as it parses the message twice

        result = Message.new(irc_message)
        case result.command
          when "PRIVMSG"
            PRIVMSG.new(irc_message)
          else
            result
        end




      end

      # parses an irc message into its prefix, command and params. using Message.parse_message
      # is normally better as it will return a more specific subclass for some types of messages
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
    # A irc message that is sent when someone sends a message to target. The
    # target could be a channel or a user
    # Create with the Message.parse_irc_message method, an instance of this class
    # will be returned when the message is the appropriate type
    class PRIVMSG < Message

      # call Message.parse_irc_message instead
      def initialize(irc_message)
        super
        @msgtarget = params[0]
        @message = params[1]
      end
      attr_reader :msgtarget
      alias_method :target, :msgtarget

      attr_reader :message
    end
  end
end
