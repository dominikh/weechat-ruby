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
        def all
          Weechat::Buffer.all.select {|b| b.channel?}.map{|b| b.channel}
        end

        def find(server, channel)
          server  = server.name if server.respond_to?(:name)
          channel = channel.name if channel.respond_to?(:name)
          b = Weechat::Buffer.find("#{server}.#{channel}", "irc")
          if b
            b.channel
          end
        end
      end

      attr_reader :server
      attr_reader :name

      def buffer
        @buffer || Weechat::Buffer.from_ptr(super) rescue nil
      end

      def ptr
        @ptr || buffer.ptr rescue nil
      end
      alias_method :pointer, :ptr

      def initialize(*args)
        if args.size == 1
          # assume buffer
          @buffer = args.first
          @ptr    = @buffer.ptr

          if not ["channel", "private"].include?(@buffer.localvar_type)
            raise Exception::NotAChannel, buffer.ptr
          end

          @server = IRC::Server.from_name(@buffer.localvar_server)
          @name   = self.to_h[:name]
        elsif args.size == 2
          # assume server(name) and channelname
          @server = args.first
          @server = IRC::Server.from_name(@server) unless @server.is_a?(IRC::Server)
          @name = args.last
        else
          raise
        end
      end

      def ==(other)
        other.is_a?(Channel) &&
          @server == other.server &&
          @name   == other.name
      end
      alias_method :eql?, "=="
      alias_method :equal?, "=="

      def get_infolist(*fields)
        if @buffer
          list = Weechat::Infolist.parse("irc_channel", "", server.name, {:buffer => [:pointer, @ptr]}, *fields)
        else
          list = Weechat::Infolist.parse("irc_channel", "", server.name, {:name => [:string, @name]}, *fields)
        end

        list.empty? ? [{}] : list
      end

      def joined?
        !!self.buffer
      end

      def part(reason="")
        raise Exception::NotJoined unless joined?
        @server.command("/part #{self.name} #{reason}")
      end

      def join(password = "")
        @server.command("/join #{self.name} #{password}")
      end

      def rejoin(password = "")
        part(reason)
        join(password)
      end
      alias_method :cycle, :rejoin

      def nicks
        raise Exception::NotJoined unless joined?
        Weechat::Infolist.parse("irc_nick", "",
                                "#{self.server.name},#{self.name}").map {|user|
          IRC::User.new(user.merge({:channel => self}))
        }
      end
      alias_method :users, :nicks

      def command(*parts)
        raise Exception::NotJoined unless joined?
        @buffer.command(*parts)
      end
      alias_method :send_command, :command
      alias_method :exec, :command
      alias_method :execute, :command

      def send(*text)
        # FIXME allow sending to not joined channels
        raise Exception::NotJoined unless joined?
        @buffer.send(*text)
      end
      alias_method :privmsg, :send
      alias_method :say, :send
    end # Channel

    class Query < Channel
      init_properties
      @type = "channel"

      [:join, :rejoin, :part, :nicks].each do |m|
        undef_method m
      end

      class << self
        def all
          Weechat::Buffer.all.select {|b| b.query?}.map{|b| b.query}
        end

        def find(server, nick)
          server  = server.name if server.respond_to?(:name)
          nick    = nick.name if nick.respond_to?(:name)
          b = Weechat::Buffer.find("#{server}.#{nick}", "irc")
          if b
            b.query
          end
        end
      end # eigenclass

      def recipient
        self.name
      end
    end # Query
  end
end
