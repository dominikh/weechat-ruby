module Weechat
  class Command < Hook
    attr_reader :command
    attr_reader :description
    attr_reader :args
    attr_reader :args_description
    attr_reader :completion
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
