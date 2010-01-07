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

    class WEECHAT_RC_OK < ::Exception; end
    class WEECHAT_RC_ERROR < ::Exception; end
    class WEECHAT_RC_OK_EAT < ::Exception; end

    # This exception gets raised when one tries to receive the channel
    # of a buffer which does not represent one.
    class NotAChannel < RuntimeError; end

    class UnknownServer < RuntimeError; end

    class NotJoined < RuntimeError; end
  end
end
