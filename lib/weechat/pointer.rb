module Weechat
  module Pointer
    attr_reader :ptr
    alias_method :pointer, :ptr

    def to_s
      @ptr
    end

    def initialize(ptr)
      @ptr = ptr
    end

    def ==(other)
      @ptr == other.ptr
    end
    alias_method :eql?, :==
  end
end
