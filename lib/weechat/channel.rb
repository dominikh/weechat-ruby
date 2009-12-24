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

      class << self
        def channels
          Weechat::Buffer.all.select {|b| b.channel?}.map{|b| b.channel}
        end
        alias_method :all, :channels

        def find(server, channel)
          server  = server.name if server.respond_to?(:name)
          channel = channel.name if channel.respond_to?(:name)
          Weechat::Buffer.find("irc", "#{server}.#{channel}")
        end
      end

      attr_reader :buffer
      def initialize(buffer)
        @buffer = Buffer.new(buffer.to_s)
        @ptr    = @buffer.ptr
        if not ["channel"].include?(@buffer.localvar_type)
          raise Exception::NotAChannel, buffer.ptr
        end
      end

      def get_infolist(*fields)
        list = Weechat::Infolist.parse("irc_channel", "", server.name, {:buffer => [:pointer, @ptr]}, *fields)
        list.empty? ? [{}] : list
      end

      def server
        IRC::Server.new(@buffer.localvar_server)
      end

      def part(reason="")
        @buffer.command("/part #{self.name} #{reason}")
      end

      def join(password = "")
        @buffer.command("/join #{self.name} #{password}")
      end

      def rejoin(password = "")
        part(reason)
        join(password)
      end
      alias_method :cycle, :rejoin

      def nicks
        Weechat::Infolist.parse("irc_nick", "",
                                "#{self.server.name},#{self.name}").map {|user|
          IRC::User.new(user.merge({:channel => self}))
        }
      end
      alias_method :users, :nicks

      def command(*parts)
        @buffer.command(*parts)
      end
      alias_method :send_command, :command
      alias_method :exec, :command
      alias_method :execute, :command

      def send(*text)
        @buffer.send(*text)
      end
      alias_method :privmsg, :send
      alias_method :say, :send
    end
  end
end
