module Weechat
  # Class that adds a hook to a weechat event. Has a callback that is called when the
  # event occurs. Overridden by subclasses for specific hooks
  # Each hook as an unique ID, which is passed to the middle-man
  #
  # callback, which then calls the appropriate callback.
  class Hook
    include Weechat::Pointer
    @@unique_id = 0

    @hook_classes = [self]
    class << self
      attr_reader :hook_classes

      def inherited(by)
        by.init
        @hook_classes << by
      end

      # returns all active hooks
      def all; @hooks; end

      def init
        @hooks = {}
      end
    end

    init

    attr_reader :id
    attr_reader :callback
    def initialize(*args)
      @id       = self.class.compute_free_id
      @ptr      = nil
      @callback = nil
      @hooked   = true
      self.class.register(self)
    end

    def callback=(callback)
      @callback = EvaluatedCallback.new(callback)
    end

    class << self
      alias_method :hook, :new
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
      return @callback.call(*args)
    end

    # finds the hook with the given id
    def self.find_by_id(id)
      @hooks[id.to_i]
    end

    # Returns a new, unique ID.
    def self.compute_free_id
      @@unique_id += 1
    end

    # registers the hook so it will be called when the event the hook
    # is hooked to occurs
    def self.register(hook)
      @hooks[hook.id] = hook
    end

    # unregisters the hook
    def self.unregister(hook)
      @hooks.delete hook.id
    end
  end
end
