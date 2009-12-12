# -*- coding: utf-8 -*-
require 'date'

module Weechat
  module IRC
    class Server
      attr_reader :name
      PROCESSORS = {
        [:buffer] => lambda {|b|
          if b.empty?
            nil
          else
            Weechat::Buffer.new(b)
          end
        },
        [:ipv6, :ssl, :ssl_verify,
         :autoconnect, :autoreconnect,
         :autorejoin, :temp_server,
         :is_connected, :ssl_connected,
         :reconnect_join, :disable_autojoin,
         :is_away] => lambda {|i| i == 0 ? false : true },
        [:reconnect_start, :command_time,
         :away_time, :lag_next_check,
         :last_user_message] => lambda {|v| DateTime.parse(v)},
      }

      MAPPINGS = {
        :autoconnect? => :autoconnect,
        :autoreconnect? => :autoreconnect,
        :autorejoin? => :autorejoin,
        :temp_server? => :temp_server,
        :connected? => :is_connected,
        :ssl_connected? => :ssl_connected,
        :reconnect_join? => :reconnect_join,
      }

      def autojoin?
        !disable_autojoin
      end

      def initialize(name)
        @name = name
      end

      class << self
        alias_method :from_name, :new
      end

      def self.buffers
        servers = []
        Weechat::Infolist.parse("irc_server").each do |server|
          servers << Server.new(server[:name])
        end
        servers
      end
      class << self
        alias_method :all, :buffers
      end

      # TODO method for creating a new server

      def data
        Weechat::Infolist.parse("irc_server", "", @name).first
      end

      def respond_to?(m)
        if data.has_key?(m.to_sym)
          true
        else
          super
        end
      end

      def method_missing(m, *args)
        m = MAPPINGS[m] || m
        properties = data
        if properties.has_key?(m) and args.size == 0
          v = properties[m]
          PROCESSORS.each do |key, value|
            if key.include?(m)
              v = value.call(v)
              break
            end
          end
          return v
        else
          super
        end
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
