module Weechat
  class Command < Hook
    attr_reader :command
    attr_reader :description
    attr_reader :args
    attr_reader :args_description
    attr_reader :completion
    def initialize(command, description, args=nil, args_description=nil, completion=nil, &callback)
      super
      command = command.to_s
      command[0..0] = '' if command[0..0] == '/'
      @command          = command
      @description      = description
      @args             = args
      @args_description = args_description
      @completion       = completion
      @callback         = callback
      @ptr              = Weechat.hook_command(command,
                                       description.to_s,
                                       args.to_s,
                                       args_description.to_s,
                                       completion.to_s,
                                       "command_callback",
                                       id.to_s)
    end

    class << self
      def find_by_command(name)
        @hooks.values.find {|h| h.command == name}
      end
      alias_method :find_by_name, :find_by_command
    end
  end
end
