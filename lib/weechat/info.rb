module Weechat
  # Note: As opposed to plain WeeChat, we properly parse arguments
  # given to a command, like a shell would.
  class Info < Hook
    attr_reader :name
    attr_reader :description
    def initialize(name, description, &callback)
      super
      @name, @description = name, description
      @callback         = callback
      @ptr              = Weechat.hook_info(name, description, "info_callback", id.to_s)
    end
  end
end
