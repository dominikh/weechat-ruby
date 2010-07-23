module Weechat
  module IRC
    class Whois
      attr_reader :data

      def populated?
        @populated
      end

      def process_reply(line)
        ret = line
        m = Weechat::IRC::Message.new(line.message)
        m.params.shift

        nick = m.params.first
        if nick == @user.name
          ret = nil

          case m.command
          when "401", "318" # ERR_NOSUCHNICK, RPL_ENDOFWHOIS
            # NOTE: 401 (no such nick) may not result in a 318
            @hooks.each do |hook|
              hook.unhook
            end
            @hooks = []
            @populated = true

            if @block
              @block.call(self)
            end

          when "311" # RPL_WHOISUSER
            @data[:nick] = m.params[0]
            @data[:user] = m.params[1]
            @data[:host] = m.params[2]
            @data[:real_name] = m.params[4]

          when "312" # RPL_WHOISSERVER

          when "313" # RPL_WHOISOPERATOR
            @data[:operator] = true

          when "317" # RPL_WHOISIDLE
            @data[:idle] = m.params.first.to_i

          when "301" # RPL_AWAY
            @data[:away_reason] = m.params.last

          when "319" # RPL_WHOISCHANNELS
            m.params[1].split(" ").each do |channel|
              if channel !~ /^([&#!.~]|\+{2}).+$/
                channel[0..0] = ""
              end

              @data[:channels] << Weechat::IRC::Channel.new(@user.server, channel)
            end
          end
        end

        ret
      end

      def initialize(user, &block)
        @data = {
          :nick        => "",
          :user        => "",
          :host        => "",
          :real_name   => "",
          :operator    => false,
          :idle        => 0,
          :away_reason => "",
          :channels    => [],
        }
        @hooks = []
        @populated = false
        @block = block #async callback
        @user = user

        # DONE: 301, 311, 313, 317, 318, 319, 401
        # CONSIDERED: 312
        # TODO: 307, 310, 320, 338, 330, 378, 379, 671
        [301,307,310,311,312,313,317,318,319,320,338,330,378,379,401,671].each do |numeric|
          @hooks << Weechat::Modifier.new("irc_in_#{numeric}") {|modifier, line| process_reply(line) }
        end

        user.server.exec("/whois #{user.name}")
      end

      def method_missing(m, *args)
        if @data.has_key?(m.to_sym)
          @data[m.to_sym]
        else
          super
        end
      end
    end # Whois
  end
end
