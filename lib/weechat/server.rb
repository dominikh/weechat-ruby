# -*- coding: utf-8 -*-
require 'date'

module Weechat
  module IRC
    class Server
      extend Weechat::Properties

      attr_reader :name
      @transformations = {
        [:buffer] => lambda {|b|
          if b.empty?
            nil
          else
            Weechat::Buffer.from_ptr(b)
          end
        },
        [:ipv6, :ssl, :ssl_verify, :autoconnect, :autoreconnect,
         :autorejoin, :temp_server, :is_connected, :ssl_connected,
         :reconnect_join, :disable_autojoin, :is_away] => lambda {|v|
          Weechat.integer_to_bool(v)
        },
        [:reconnect_start, :command_time, :away_time, :lag_next_check,
         :last_user_message] => lambda {|v| Date.parse(v) },
        [:nicks] => lambda {|v| v.split(",") }
      }.freeze

      @mappings = {
        :ipv6? => :ipv6,
        :ssl?  => :ssl,
        :autoconnect? => :autoconnect,
        :autoreconnect? => :autoreconnect,
        :autorejoin? => :autorejoin,
        :temp_server? => :temp_server,
        :connected? => :is_connected,
        :ssl_connected? => :ssl_connected,
        :join_on_reconnect? => :reconnect_join,
        :away? => :is_away,
      }.freeze

      init_properties

      def autojoin?
        !disable_autojoin
      end

      attr_reader :ptr
      def initialize(*args)
        # TODO allow the creation of new channels using commands
      end

      def ==(other)
        @ptr == other.ptr
      end
      alias_method :eql?, "=="
      alias_method :equal?, "=="

      def hash
        @ptr.hash
      end

      class << self
        def from_name(name)
          o = allocate
          o.instance_variable_set(:@ptr, name)
          o.instance_variable_set(:@name, name.to_s)
          raise Exception::UnknownServer, name if o.get_infolist.empty?
          o
        end

        def servers
          servers = []
          Weechat::Infolist.parse("irc_server").each do |server|
            servers << Server.from_name(server[:name])
          end
          servers
        end
        alias_method :all, :servers
      end

      def channels
        channels = []
        Weechat::Infolist.parse("irc_channel", "", @name).each do |channel|
          channels << IRC::Channel.new(channel[:buffer])
        end
        channels
      end

      def connect
        return false if connected?
        Weechat.exec("/connect #{@name}")
      end

      def disconnect
        return false if not connected?
        self.buffer.exec("/disconnect #{@name}")
      end

      # TODO method for creating a new server
      def get_infolist(*fields)
        Weechat::Infolist.parse("irc_server", "", @name, {}, *fields)
      end
    end
  end
end
__END__
 name..........................: str 'quakenet'
     │ buffer........................: ptr 0x9bb2438
     │ buffer_name...................: str 'server.quakenet'
     │ buffer_short_name.............: str 'quakenet'
     │ addresses.....................: str 'irc.quakenet.org/6667'
     │ proxy.........................: str ''
     │ ipv6..........................: int 0
     │ ssl...........................: int 0
     │ ssl_cert......................: str ''
     │ ssl_dhkey_size................: int 2048
     │ ssl_verify....................: int 1
     │ password......................: str ''
     │ autoconnect...................: int 0
     │ autoreconnect.................: int 1
     │ autoreconnect_delay...........: int 30
     │ nicks.........................: str 'dominikh,dominikh1,dominikh2,dominikh3,dominikh4'
     │ username......................: str 'dominikh'
     │ realname......................: str 'Dominik Honnef'
     │ local_hostname................: str ''
     │ command.......................: str ''
     │ command_delay.................: int 0
     │ autojoin......................: str ''
     │ autorejoin....................: int 0
     │ temp_server...................: int 0
     │ index_current_address.........: int 0
     │ current_ip....................: str '85.236.110.226'
     │ sock..........................: int 8
     │ is_connected..................: int 1
     │ ssl_connected.................: int 0
     │ unterminated_message..........: str ''
     │ nick..........................: str 'dominikh1'
     │ nick_modes....................: str 'i'
     │ prefix........................: str '@+'
     │ reconnect_start...............: tim 1970-01-01 01:00:00
     │ command_time..................: tim 1970-01-01 01:00:00
     │ reconnect_join................: int 0
     │ disable_autojoin..............: int 0
     │ is_away.......................: int 0
     │ away_message..................: str ''
     │ away_time.....................: tim 1970-01-01 01:00:00
     │ lag...........................: int 43
     │ lag_check_time................: buf
     │ lag_next_check................: tim 2009-12-12 16:56:28
     │ last_user_message.............: tim 2009-12-12 16:48:21
