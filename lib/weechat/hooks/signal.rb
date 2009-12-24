module Weechat
  module Hooks
    class Signal < Hook
      def initialize(signal='*', &callback)
        super
        @callback = EvaluatedCallback.new(callback)
        @ptr      = Weechat.hook_signal(signal, "signal_callback", id.to_s)
      end

      class << self
        def send(signal, type, data)
          Weechat.hook_signal_send(signal.to_s, type.to_s, data.to_s)
        end
        alias_method :exec, :send
      end
    end
  end
end
