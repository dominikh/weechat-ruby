module Weechat
  module IRC
    class Channel
      include Weechat::Pointer
      extend Weechat::Properties

      @transformations = {
      }.freeze

      @mappings = {
      }.freeze

      init_properties

      attr_reader :buffer
      def initialize(buffer)
        @buffer = Buffer.new(buffer.to_s)
        @ptr    = @buffer.ptr
        if not ["channel"].include?(@buffer.localvar_type)
          raise Exception::NotAChannel, buffer.ptr
        end
      end

      def get_infolist
        Weechat::IRC::Server.all.map{|server|
          Weechat::Infolist.parse("irc_channel", "", server.name).find{|channel|
            channel[:buffer] == @ptr
          }
        }.compact
      end

      def server
        IRC::Server.new(@buffer.localvar_server)
      end

      def part(reason="")
        @buffer.command("/part #{self.name} #{reason}")
      end

      def join
        @buffer.command("/join #{self.name}")
      end

      def rejoin(reason="")
        part(reason)
        join
      end
      alias_method :cycle, :rejoin
    end
  end
end
