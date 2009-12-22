module Weechat
  class Modifier < Hook
    attr_reader :modifier
    def initialize(modifier, &callback)
      super
      @modifier = modifier.to_s
      @callback         = Callback.new(callback)
      @ptr              = Weechat.hook_modifier(modifier, "modifier_callback", id.to_s)
    end

    alias_method :exec, :call

    class << self
      def call(modifier, data, string)
        Weechat.hook_modifier_exec(modifier.to_s, data.to_s, string.to_s)
      end
      alias_method :exec, :call
    end
  end
end
