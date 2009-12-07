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
    alias_method :eql?, "=="
    alias_method :equal?, "=="

    def hash
      @ptr.hash
    end

    def inspect
      sprintf "#<%s:0x%x @ptr=%p>", self.class, object_id << 1, @ptr
    end
  end
end
