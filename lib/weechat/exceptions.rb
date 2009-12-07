module Weechat
  module Exception
    # This exception gets raised whenever one tries to read a property
    # that doesn't exist.
    #
    # @see Buffer#get_property
    # @see Window#get_property
    class UnknownProperty < RuntimeError; end

    # This exception gets raised whenever one tries to set a property
    # that cannot be set.
    #
    # @see Buffer#set_property
    # @see Window#set_property
    class UnsettableProperty < RuntimeError; end

    # This exception gets raised whenever one tries to set a property,
    # supplying a value not suiting it.
    class InvalidPropertyValue < RuntimeError; end

    # This exception gets raised when one tries to create a buffer
    # with the name of an already existing one.
    #
    # @see Buffer.create
    class DuplicateBufferName < RuntimeError; end
  end
end
