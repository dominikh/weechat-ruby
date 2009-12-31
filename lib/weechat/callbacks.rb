module Weechat
  module Callbacks
    @unique_id = 0
    @callbacks = {}

    class << self
      attr_reader :callbacks
      attr_reader :unique_id

      def compute_free_id
        @unique_id += 1
      end
    end

    def call_callback(id, type, *args)
      return callbacks[id.to_i][type].call(*args)
    end

    def register_callback(args = {})
      callbacks[unique_id] = args
    end

    def compute_free_id
      Callbacks.compute_free_id
    end

    def callbacks
      Callbacks.callbacks
    end

    def unique_id
      Callbacks.unique_id
    end
  end
end
