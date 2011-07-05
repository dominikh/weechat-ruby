module Weechat
  module Hooks
    # Hooks for adding behaviour when a line is printed out on a buffer
    class Print < Hook
      # Creates a new Print hook. By default it will be called for every printed
      # line in every buffer. Set the :buffer, :tags and :message options
      # to only respond to a subset of messages
      # @param [Hash] opts Options to determine when and how the Print hook is called
      # @option opts [Buffer] :buffer If supplied, only printed lines from this Buffer
      #   will be printed. Default nil
      # @option opts [Array<String>] :tags Tags for the message TODO how does this filter
      # @option opts [String] :message TODO how does this filter
      # @option opts [Boolean] :strip_colors whether color chars should be filtered
      #   before being sent to the hook
      #
      # @yield (line) The callback that should handle the line
      # @yieldparam [PrintedLine] line
      def initialize(opts = {}, &callback)
        super
        buffer = opts[:buffer] || "*"
        tags = opts[:tags] || []
        message = opts[:message] || ''
        strip_colors = opts[:strip_colors] || false

        buffer = buffer.ptr if buffer.respond_to?(:ptr)
        tags = tags.join(",")
        strip_colors = Weechat.bool_to_integer(strip_colors)
        @callback = EvaluatedCallback.new(callback)
        @ptr      = Weechat.hook_print(buffer, tags, message, strip_colors, "print_callback", id.to_s)
      end
    end
  end
end
