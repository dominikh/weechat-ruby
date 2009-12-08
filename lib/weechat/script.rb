module Weechat
  class Script
    include Weechat::Pointer
    extend Weechat::Properties

    init_properties

    def initialize(ptr, plugin)
      super(ptr)
      @plugin = plugin
    end

    def get_infolist
      Weechat::Infolist.parse("#{@plugin.name}_script", @ptr)
    end
  end
end
