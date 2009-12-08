module Weechat
  class Callback
    def initialize(callback)
      @callback = callback
    end

    def call(*args)
      return Weechat::Utilities.evaluate_call {@callback.call(*args)}
    end
  end
end
