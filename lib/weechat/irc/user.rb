module Weechat
  module IRC
    class User
      attr_reader :name
      attr_reader :host
      attr_reader :flags
      attr_reader :color
      attr_reader :channel
      attr_reader :server


      # FIXME make users server agnostic
      def initialize(args = {})
        @name = args[:name]
        @identifier = IRC::Identifier.new(args[:host])
        @flags, @color, @channel = args.values_at(:flags, :color, :channel)
        # @flags, @color = args.values_at(:flags, :color)
        @server = @channel.server
      end

      %w(chanowner? chanadmin? chanadmin2? op?
         halfop? voice? away? chanuser?).each_with_index do |method, bit|
        define_method(method) {(@flags & (2 ** bit)) > 0}
      end
      alias_method :opped?, :op?
      alias_method :voiced?, :voice?

      def ==(other)
        @name == other.name && @host == other.host #&& @channel == other.channel
      end
      alias_method :eql?, "=="
      alias_method :equal?, :eql?

      def whois
        Weechat::IRC::Whois.new(self) { |w| yield(w) if block_given? }
      end

      def real_name
        whois { |w| yield(w.real_name) if block_given? }
      end

      def channels
        whois { |w| yield(w.channels) if block_given? }
      end

      def op
        @channel.exec("/op #@name")
      end

      def halfop
        @channel.exec("/halfop #@name")
      end

      def voice
        @channel.exec("/voice #@name")
      end

      def deop
        @channel.exec("/deop #@name")
      end

      def dehalfop
        @channel.exec("/dehalfop #@name")
      end

      def devoice
        @channel.exec("/devoice #@name")
      end

      def kick(reason="")
        @channel.exec("/kick #@name #{reason}")
      end

      def ban
        @channel.exec("/ban #@name")
      end

      def unban
        @channel.exec("/unban #@name")
      end

      def kickban(reason="")
        kick(reason)
        ban
      end
    end # User
  end # IRC
end # Weechat
