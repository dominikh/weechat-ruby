module Weechat
  class Command < Hook
    attr_reader :command
    attr_reader :description
    attr_reader :args
    attr_reader :args_description
    attr_reader :completion
    # Creates a new command, which can then be invoked with /command-name args
    # also will register help for the command
    # @overload new(name, description)
    #   Creates a command with a name and description
    #   @param [String] name The name of the command
    #   @param [String] description The description of the command, will appear in help
    #   @yield (buffer, input) The action that is performed when the command is run
    #   @yieldparam [Buffer] buffer The buffer the command was run in
    #   @yieldparam [String] input The string passed to the command (or "" if no string was passed)
    # @overload new(opts)
    #   Create a command using various options
    #   @param [Hash] initialize(opts)
    #   @option opts [String] :name The name of the command
    #   @option opts [String] :description The description of the command
    #   @option opts [Array, #to_s] :completion TODO document
    #   @option opts [Hash, Array, #to_s] :args_description TODO document
    #   @yield (buffer, input) The action that is performed when the command is run
    #   @yieldparam [Buffer] buffer The buffer the command was run in
    #   @yieldparam [String] input The string passed to the command (or "" if no string was passed)
    def initialize(*args, &callback)
      args = args.map{|e| e.dup}
      raise "No callback specified" if callback.nil?
      super

      if args.size == 2
        @command, @description = args
      elsif args.size == 1 && args[0].is_a?(Hash)
        @command, @description, @args, =
        args[0].values_at(:command, :description, :args)

        @completion = case args[0][:completion]
                      when Array
                        args[0][:completion].join(" || ")
                      else
                        args[0][:completion].to_s
                      end

        case args[0][:args_description]
        when Hash
          lines = []
          color = Weechat.color("white")
          reset = Weechat.color("reset")
          max_length = args[0][:args_description].keys.map {|k| k.size}.max
          args[0][:args_description].each do |key, value|
            key = (" " * (max_length - key.size)) + key
            lines << "#{color}#{key}: #{reset}#{value}"
          end
          @args_description = lines.join("\n")
        when Array
          @args_description = args[0][:args_description].join("\n")
        else
          @args_description = args[0][:args_description].to_s
        end

      else
        raise "Please supply two arguments or a hash"
      end

      @command[0..0] = '' if @command[0..0] == '/'
      @callback         = EvaluatedCallback.new(callback)
      @ptr              = Weechat.hook_command(@command,
                                       @description.to_s,
                                       @args.to_s,
                                       @args_description.to_s,
                                       @completion.to_s,
                                       "command_callback",
                                       id.to_s)
    end

    class << self
      def find_by_command(name)
        name[0..0] = '' if name[0..0] == '/'
        @hooks.values.find {|h| h.command == name}
      end
      alias_method :find_by_name, :find_by_command
    end
  end
end
