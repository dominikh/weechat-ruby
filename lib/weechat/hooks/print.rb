module Weechat
  module Hooks
    class Print < Hook
      def initialize(buffer='*', tags = [], message = '', strip_colors = false, &callback)
        super
        buffer = buffer.ptr if buffer.respond_to?(:ptr)
        tags = tags.join(",")
        strip_colors = Weechat.bool_to_integer(strip_colors)
        @callback = Callback.new(callback)
        @ptr      = Weechat.hook_print(buffer, tags, message, strip_colors, "print_callback", id.to_s)
      end
    end
  end
end
