module Weechat
  class Option < Blankslate
    @options = [] # we can't use a Hash because hashing
    # blankslate... breaks things


    def self.options
      @options
    end

    def initialize(config, option)
      self.__class__.options << [config, option, self]
      @old_obj     = config.__get(option)
      @config = config
      @option = option
      @frozen      = false
    end

    def __freeze__
      @frozen = true
    end

    def method_missing(m, *args)
      if @frozen
        obj = @old_obj
      else
        obj = @config.__get(@option)
      end
      ret = obj.__send__(m, *args)

      if (@old_obj != obj) && !@frozen
        @config.set!(@option, obj)
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
