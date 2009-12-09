module Weechat
  # Note: As opposed to plain WeeChat, we properly parse arguments
  # given to a command, like a shell would.
  class Modifier < Hook
    attr_reader :modifier
    def initialize(modifier, &callback)
      super
      @modifier = modifier.to_s
      @callback         = callback # we do not use the Callback class
                                   # here because we need the return
                                   # value of the callback
      @ptr              = Weechat.hook_modifier(modifier, "modifier_callback", id.to_s)
    end
  end
end
