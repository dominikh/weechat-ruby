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
          servers << IrcServer.new(server[:name])
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
        if data.has_key?(m) and args.size == 0
          v = data[m]
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
{:name=>"freenode",
  :buffer_name=>"",
  :buffer_short_name=>"",
  :addresses=>"chat.freenode.net/6667",
  :proxy=>"",
  :ssl_cert=>"",
  :ssl_dhkey_size=>2048,
  :password=>"",
  :autoreconnect_delay=>30,
  :nicks=>"dominikh,dominikh1,dominikh2,dominikh3,dominikh4",
  :username=>"dominikh",
  :realname=>"Dominik Honnef",
  :local_hostname=>"",
  :command=>"",
  :command_delay=>0,
  :autojoin=>"",
  :index_current_address=>0,
  :current_ip=>"",
  :sock=>-1,
  :unterminated_message=>"",
  :nick=>"",
  :nick_modes=>"",
  :prefix=>"",
  :away_message=>"",
  :lag=>0,
  :lag_check_time=>nil,
}
