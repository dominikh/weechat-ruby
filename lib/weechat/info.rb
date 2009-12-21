module Weechat
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
