module Weechat
  # Each hook as an unique ID, which is passed to the middle-man
  # callback, which then calls the appropriate callback.
  class Hook
    include Weechat::Pointer

    @hook_classes = [self]
    def self.inherited(by)
      by.init
      @hook_classes << by
    end

    def self.hooks; @hooks; end

    def self.init
      @hooks = {}
    end

    init

    attr_reader :id
    attr_reader :callback
    def initialize(*args)
      @id       = self.class.compute_free_id
      @ptr      = nil
      @callback = nil
      @hooked   = true
    end

    # def to_s
    #   @ptr
    # end

    def hooked?
      @hooked
    end

    # low level unhooking, no checks whatsoever. Basically used for
    # unhooking foreign hooks.
    def self.unhook(ptr)
      Weechat.unhook(ptr)
    end

    # Note: this also unhooks all hooks that were made using the API
    def self.unhook_all
      @hook_classes.each do |hook_class|
        hook_class.hooks.values.each {|hook| hook.unhook}
      end
      Weechat.unhook_all
    end

    def unhook(_raise = true)
      if _raise and !hooked?
        raise "not hooked"
      end

      self.class.unhook(@ptr)
      self.class.unregister(self)
      @callback = nil
      @hooked = false
      true
    end

    def call(*args)
      @callback.call(*args)
      Weechat::WEECHAT_RC_OK
    end

    def self.find_by_id(id)
      @hooks[id.to_i]
    end

    def self.compute_free_id
      (@hooks.keys.max || -1) + 1
    end

    def self.register(hook)
      @hooks[hook.id] = hook
    end

    def self.unregister(hook)
      @hooks.delete hook.id
    end
  end
end
