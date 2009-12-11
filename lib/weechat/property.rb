module Weechat
  class Property < Blankslate
    @properties = [] # we can't use a Hash because hashing
                     # blankslate... breaks things

    
    def self.properties
      @properties
    end

    def initialize(weechat_obj, property)
      self.__class__.properties << [weechat_obj.ptr, property, self]
      @old_obj     = weechat_obj.__get_property(property)
      @weechat_obj = weechat_obj
      @property    = property
      @settable    = weechat_obj.settable_property?(property)
      @frozen      = false
    end

    def __freeze__
      @frozen = true
    end

    def method_missing(m, *args)
      if @frozen
        obj = @old_obj
      else
        obj = @weechat_obj.__get_property(@property)
      end
      ret = obj.__send__(m, *args)

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
