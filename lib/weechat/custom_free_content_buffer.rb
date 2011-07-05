# encoding: UTF-8

module Weechat
  # Override to create a custom buffer with free content. These buffers
  # don't work on a line basis (so methods such as puts won't work). They
  # work by setting specific lines, which can be done with the
  # print_line method
  class CustomFreeContentBuffer < CustomBuffer
    def initialize(name)
      super
      self.type = :free
    end


    # Sets a given line in the buffer
    # @param [Integer] line_number The line number to print to
    # @param [String] line The line to print
    # @return [void]
    def print_line(line_number, line)
      Weechat.print_y(self.ptr, line_number, line)
    end

  end
end
