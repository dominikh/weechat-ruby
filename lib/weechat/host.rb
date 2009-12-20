module Weechat
  module IRC
    class Host
      attr_reader :user
      attr_reader :host
      def initialize(string)
        @user, @host = string.split("@")
      end

      def identd?
        @user[0..0] != "~"
      end
      alias_method :ident?, :identd?
    end
  end
end
