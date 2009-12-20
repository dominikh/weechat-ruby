module Weechat
  class Property < Blankslate
    @properties = [] # we can't use a Hash because hashing
                     # blankslate... breaks things


    def initialize(weechat_obj, property)
      @old_obj     = weechat_obj.__get_property(property)
      @weechat_obj = weechat_obj
      @property    = property
      @settable    = weechat_obj.settable_property?(property)
      @frozen      = false
    end

    def __weechat_obj__
      @weechat_obj
    end

    def __property__
      @property
    end

    def __freeze__
      @frozen = true
    end

    def method_missing(m, *args, &block)
      if @frozen
        obj = @old_obj
      else
        obj = @weechat_obj.__get_property(@property)
      end
      ret = obj.__send__(m, *args, &block)

      if (@old_obj != obj) && @settable && !@frozen
        @weechat_obj.set_property(@property, obj)
      end

      unless @frozen
        begin
          @old_obj = obj.dup
        rescue TypeError
          @old_obj = obj
        end
      end

      ret
    end
  end
end
