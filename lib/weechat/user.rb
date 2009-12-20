module Weechat
  module IRC
    class User
      attr_reader :name
      attr_reader :host
      attr_reader :flags
      attr_reader :color
      attr_reader :channel
      def initialize(args = {})
        @name = args[:name]
        @host = IRC::Host.new(args[:host])
        @flags, @color, @channel = args.values_at(:flags, :color, :channel)
      end

      %w(chanowner? chanadmin? chanadmin2? op?
         halfop? voice? away? chanuser?).each_with_index do |method, bit|
        define_method(method) {(@flags & (2 ** bit)) > 0}
      end
      alias_method :opped?, :op?
      alias_method :voiced?, :voice?

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
    end
  end
end
