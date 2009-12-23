module Weechat
  module Hooks
    class Signal < Hook
      def initialize(signal='*', &callback)
        super
        @callback = EvaluatedCallback.new(callback)
        @ptr      = Weechat.hook_signal(signal, "signal_callback", id.to_s)
      end
    end
  end
end
