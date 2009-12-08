module Weechat
  module Hooks
    class CommandRunHook < Hook
      # Returns a new instance of CommandRunHook
      #
      # @param [Boolean] also_arguments If true, two hooks will be
      #   made, one for "$command" and one for "$command *", matching
      #   both calls with and without arguments
      def initialize(command, also_arguments = false, &callback)
        super
        @command  = if command.is_a? Command
                      command.command
                    else
                      command.to_s
                    end

        @callback = callback
        @ptr      = Weechat.hook_command_run(@command, "command_run_callback", id.to_s)
        if also_arguments
          @ptr2 = Weechat.hook_command_run("#@command *", "command_run_callback", id.to_s)
        end
      end

      def unhook(*args)
        super
        self.class.unhook(@ptr2) if @ptr2
      end
    end
  end
end
