module Weechat
  class Process < Hook
    # Returns a new instance of Process
    #
    # @param [String] command Command to execute
    # @param [Integer] timeout Timeout after which to terminate the process
    # @param [Boolean] collect If true, buffer output until process ends

    attr_reader :collect
    def initialize(command, timeout = 0, collect = false, &callback)
      super
      @command  = command
      @collect  = collect
      @stdout, @stderr = [], []
      @callback = EvaluatedCallback.new(callback)
      @ptr      = Weechat.hook_process(command, timeout, "process_callback", id.to_s)
    end

    def stdout
      @stdout.join("")
    end

    def stderr
      @stderr.join("")
    end

    def buffer(stdout, stderr)
      @stdout << stdout
      @stderr << stderr
    end
  end
end
