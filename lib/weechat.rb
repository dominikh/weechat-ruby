if not defined? Weechat
  raise LoadError.new('The weechat gem can only be required from scripts ' +
  'that are run under the WeeChat IRC client using the Ruby plugin.')
end

require 'pp'

module Weechat
  VERSION = "0.0.1"
  module Helper
    def command_callback(id, buffer, args)
      Weechat::Command.find_by_id(id).call(Weechat::Buffer.new(buffer), args)
    end

    def command_run_callback(id, buffer, command)
      Weechat::Hooks::CommandRunHook.find_by_id(id).call(Weechat::Buffer.new(buffer), command)
    end

    def timer_callback(id, remaining)
      Weechat::Timer.find_by_id(id).call(remaining.to_i)
    end

    def input_callback(method, buffer, input)
      Weechat::Buffer.call_input_callback(method, buffer, input)
    end

    def close_callback(method, buffer)
      Weechat::Buffer.call_close_callback(method, buffer)
    end

    def info_callback(id, info, arguments)
      Weechat::Info.find_by_id(id).call(info, arguments).to_s
    end

    ModifierCallbackTransformations = {
      ['irc_color_decode', 'irc_color_encode'] => lambda { |v| Weechat.integer_to_bool(v) },
      [/^bar_condition_.+$/]                   => lambda { |v| Weechat::Window.new(v) },
      ["input_text_content", "input_text_display",
       "input_text_display_with_cursor"]       => lambda { |v| Weechat::Buffer.new(v) },
      ["weechat_print"]                        => lambda { |v|
        parts = v.split(";")
        parts[0] = Weechat::Plugin.find(parts[0])
        parts[1] = Weechat::Buffer.find(parts[1], parts[0])
        if parts[2]
          parts[2] = parts[2].split(",")
        else
          parts[2] = []
        end
        parts
      },
    }

    ModifierCallbackRTransformations = {
      [/^bar_condition_.+$/] => lambda { |v| Weechat.bool_to_integer(v) },
    }

    def modifier_callback(id, modifier, modifier_data, s)
      modifier_data = Weechat::Utilities.apply_transformation(modifier, modifier_data, ModifierCallbackTransformations)
      ret = Weechat::Modifier.find_by_id(id).call(*modifier_data, Weechat::Line.parse(s))
      return Weechat::Utilities.apply_transformation(modifier, ret, ModifierCallbackRTransformations).to_s
    end
  end

  class << self
    def exec(command, buffer=nil)
      Weechat.command(buffer.to_s, command)
    end
    alias_method :send_command, :exec
    alias_method :execute, :exec

    def puts(text, buffer = nil)
      buffer = case buffer
               when nil
                 ""
               when :current
                 Weechat::Buffer.current
               else
                 buffer
               end
      Weechat.print(buffer.to_s, text.to_s)
      nil # to mimic Kernel::puts
    end

    def p(object, buffer = nil)
      self.puts(object.inspect, buffer)
    end

    def pp(object, buffer = nil)
      puts(object.pretty_inspect, buffer)
    end

    # Writes text to the WeeChat log +weechat.log+
    #
    # @return [void]
    def log(text)
      Weechat.log_print(text)
    end

    def integer_to_bool(int)
      int.to_i == 0 ? false : true
    end

    def bool_to_integer(bool)
      bool ? 1 : 0
    end

    alias_method :old_mkdir_home, :mkdir_home
    alias_method :old_mkdir, :mkdir
    alias_method :old_mkdir_parents, :mkdir_parents
    def mkdir_home(*args)
      integer_to_bool(old_mkdir_home(*args))
    end

    def mkdir(*args)
      integer_to_bool(old_mkdir(*args))
    end

    def mkdir_parents(*args)
      integer_to_bool(old_mkdir_parents(*args))
    end

    def fifo
      Weechat.info_get("fifo_filename", "")
    end

    def compilation_date
      Date.parse(Weechat.info_get("date", ""))
    end

    def filtering?
      integer_to_bool(Weechat.info_get("filters_enabled", ""))
    end

    def keyboard_inactivity
      Weechat.info_get("inactivity", "").to_i
    end
    alias_method :inactivity, :keyboard_inactivity

    def version
      Weechat.info_get("version", "")
    end

    def charsets
      {
        :internal => Weechat.info_get("charset_internal", ""),
        :terminal => Weechat.info_get("charset_terminal", ""),
      }
    end

    def directories
      {
        :weechat   => Weechat.info_get("weechat_dir", ""),
        :lib       => Weechat.info_get("weechat_libdir", ""),
        :locale    => Weechat.info_get("weechat_localedir", ""),
        :share     => Weechat.info_get("weechat_sharedir", ""),
        :separator => Weechat.info_get("dir_separator", "")
      }
    end
    alias_method :dirs, :directories
  end
end

require 'weechat/blankslate.rb'
require 'weechat/line.rb'
require 'weechat/terminal.rb'
require 'weechat/callback.rb'
require 'weechat/property.rb'
require 'weechat/properties.rb'
require 'weechat/exceptions.rb'
require 'weechat/utilities.rb'
require 'weechat/pointer.rb'
require 'weechat/hook.rb'
require 'weechat/timer.rb'
require 'weechat/command.rb'
require 'weechat/modifier.rb'
require 'weechat/input.rb'
require 'weechat/buffer.rb'
require 'weechat/window.rb'
require 'weechat/server.rb'
require 'weechat/infolist.rb'
require 'weechat/prefix.rb'
require 'weechat/color.rb'
require 'weechat/plugin.rb'
require 'weechat/rubyext/string.rb'
require 'weechat/rubyext/boolean.rb'
require 'weechat/rubyext/object.rb'
require 'weechat/rubyext/array.rb'
require 'weechat/hooks.rb'
require 'weechat/script.rb'
require 'weechat/script/config.rb'
require 'weechat/option.rb'
require 'weechat/info.rb'
