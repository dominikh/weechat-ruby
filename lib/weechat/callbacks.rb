module Weechat
  module Callbacks
    def self.extended(by)
      by.instance_variable_set(:@callbacks, [])
    end

    def call_callback(id, type, *args)
      return @callbacks[id.to_i][type].call(*args)
    end

    # Returns all callbacks
    #
    # @return [Array<Hash{Symbol => String, #call}>] An array of hashes containing
    #   the callbacks and pointers of the objects to which the callbacks are assigned to
    # @see #input_callback
    # @see #close_callback
    def callbacks
      @callbacks
    end
  end
end
