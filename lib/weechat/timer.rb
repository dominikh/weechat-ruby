module Weechat
  class Timer < Hook
    attr_reader :interval
    attr_reader :align
    attr_reader :max
    def initialize(interval, align=0, max=0, &block)
      super
      @remaining= nil
      @callback = Callback.new(block)
      @interval = interval
      @align    = align
      @max      = max
      @ptr      = _init(interval, align, max)
      self.class.register(self)
    end

    def _init(interval, align, max)
      Weechat.hook_timer(interval, align, max, "timer_callback", @id.to_s)
    end

    def call(remaining)
      @remaining = remaining.to_i
      ret = super

      if @remaining == 0
        self.unhook
      end

      return ret
    end

    def stop
      unhook
    end

    def start
      unless @hooked
        if @remaining == 0 || @remaining.nil?
          # the timer never ran or finished already. restart it
          max = @max
        else
          # continue running hook
          max = @remaining
        end

        @ptr = _init(@interval, @align, max)
      end
    end

    def restart
      stop
      @remaining = nil
      start
    end
  end
end
