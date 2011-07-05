# encoding: UTF-8
require 'weechat/blankslate'
require 'delegate'

module Weechat
  # Subclass to create a custom buffer
  class CustomBuffer < Delegator
    @@tracked_buffers = {}

    def __getobj__
      @base_buffer
    end

    # Override to determine what should be
    # done when the user enters input
    def handle_input

    end

    # Override to add a buffer closed action
    def buffer_closed

    end

    # Creates a new instance of the custom buffer using
    # the given name
    def initialize(name)
      buffer = Buffer.new(name,
            lambda {|b, input| @@tracked_buffers[b.ptr].handle_input(input)},
            lambda {|b| @@tracked_buffers[b.ptr].buffer_closed}
      )
      super(buffer)
      @@tracked_buffers[buffer.ptr] = self
      @base_buffer = buffer

    end

  end
end
