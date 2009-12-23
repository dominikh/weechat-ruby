module Weechat
  class Modifier < Hook
    def self.inherited(by)
      Hook.inherited(by)
    end

    attr_reader :modifier
    def initialize(modifier, &callback)
      super
      @modifier = modifier.to_s
      @callback         = Callback.new(callback)
      @ptr              = Weechat.hook_modifier(modifier, "modifier_callback", id.to_s)
    end

    alias_method :exec, :call

    class << self
      def call(modifier, data, string)
        Weechat.hook_modifier_exec(modifier.to_s, data.to_s, string.to_s)
      end
      alias_method :exec, :call
    end
  end

  module Modifiers
    class Print < Weechat::Modifier
      class PrintModifierCallback < Weechat::Callback
        def call(plugin, buffer, tags, line)
          begin
            ret = @callback.call(plugin, buffer, tags, line)
          rescue => e
            Weechat::Utilities.format_exception(e)
            return line
          end
          return ret
        end
      end # PrintModifierCallback

      def initialize(&callback)
        super("weechat_print", &callback)
        @callback = PrintModifierCallback.new(callback)
      end
    end # Print

    Mappings = {
      'weechat_print' => Print,
    }
  end # Modifiers
end
