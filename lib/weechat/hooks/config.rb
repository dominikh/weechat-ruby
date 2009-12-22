module Weechat
  module Hooks
    class Config < Hook
      def initialize(option, &callback)
        super
        @callback = EvaluatedCallback.new(callback)
        @ptr      = Weechat.hook_config(option, "config_callback", id.to_s)
      end
    end
  end
end
