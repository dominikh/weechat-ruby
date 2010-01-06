module Weechat
  module IRC
    class Host
      attr_reader :nick
      attr_reader :user
      attr_reader :host

      def initialize(string)
        parts = string.split("@")
        @host = parts.last
        @nick, @user = parts.first.split("!")
      end

      def to_s
        "#{@nick}!#{@user}@#{@host}"
      end
    end

    class Prefix
      attr_reader :nick
      attr_reader :user
      attr_reader :host

      def initialize(string)
        @host, @nick, @user = nil, nil, nil
        parts = string.split("@")
        if parts.size == 1
          @nick = parts.first
        else
          @host = parts.last
          @nick, @user = parts.first.split("!")
        end
      end

      def to_s
        if @host.empty?
          @nick
        else
          "#{@nick}!#{@user}@#{@host}"
        end
      end
    end
  end
end
