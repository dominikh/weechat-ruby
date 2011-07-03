if not defined? Weechat
  raise LoadError.new('The weechat gem can only be required from scripts ' +
  'that are run under the WeeChat IRC client using the Ruby plugin.')
end

require 'pp'

module Weechat
  VERSION = "0.0.6"

  protected
  def self.included(other)
    other.__send__(:include, Script::Skeleton)
    other.__send__(:include, Weechat::Helper)
  end
  public

  # Details about a single line that has been printed in a buffer.
  # Used by the Hooks::Print hook
  class PrintedLine
    def initialize(buffer, date, tags, displayed, highlight, prefix, message)
      @buffer, @date, @tags, @displayed, @highlight = buffer, date, tags, displayed, highlight
      @prefix, @message = prefix, message
    end

    # @return [Buffer] The buffer the line was printed on
    attr_reader :buffer
    # @return [Time] The date the line was printed
    attr_reader :date
    # @return [Array<String>] The tags the line has TODO what is this?
    attr_reader :tags
    # @return [Boolean] True if line was displayed, false if it was filtered
    attr_reader :displayed
    # @return [Boolean] Whether the line was highlighted
    attr_reader :highlight

    # @return [String] The prefix of the message TODO give example
    attr_reader :prefix

    # @return [String] The message text
    attr_reader :message
  end

  # Contains the callback for linking with the low level ruby api
  # No need to call these methods manually
  module Helper
    # low level Callback method used for commands
    def command_callback(id, buffer, args)
      Weechat::Command.find_by_id(id).call(Weechat::Buffer.from_ptr(buffer), args)
    end

    # low level Callback used for running commands
    def command_run_callback(id, buffer, command)
      Weechat::Hooks::CommandRunHook.find_by_id(id).call(Weechat::Buffer.from_ptr(buffer), command)
    end

    # low level Timer callback
    def timer_callback(id, remaining)
      Weechat::Timer.find_by_id(id).call(remaining.to_i)
    end

    # low level buffer input callback
    def input_callback(method, buffer, input)
      Weechat::Buffer.call_input_callback(method, buffer, input)
    end

    # low level buffer close callback
    def close_callback(method, buffer)
      Weechat::Buffer.call_close_callback(method, buffer)
    end

    # low level bar build callback
    def bar_build_callback(id, item, window)
      Weechat::Bar::Item.call_build_callback(id, window)
    end

    # low level info callback
    def info_callback(id, info, arguments)
      Weechat::Info.find_by_id(id).call(arguments).to_s
    end

    # low level print callback
    def print_callback(id, buffer, date, tags, displayed, highlight, prefix, message)
      buffer    = Weechat::Buffer.from_ptr(buffer)
      date      = Time.at(date.to_i)
      tags      = tags.split(",")
      displayed = Weechat.integer_to_bool(displayed)
      highlight = Weechat.integer_to_bool(highlight)
      line = PrintedLine.new(buffer, date, tags, displayed, highlight, prefix, message)
      Weechat::Hooks::Print.find_by_id(id).call(line)
    end

    private

    # TODO add IRC parser
    # TODO add support for filters
    # TODO add support for ignores
    # TODO add support for infolists by pointer
    #
    SignalCallbackTransformations = {
      [/irc_(channel|pv)_opened/, /^logger_(start|stop|backlog)$/,
       /^buffer_(closing|closed|lines_hidden|moved|opened|renamed|switch)$/,
       /^buffer_(title|type)_changed$/,
       /^buffer_localvar_(added|changed|removed)$/] => lambda { |v| Weechat::Buffer.from_ptr(v) },
      [/irc_server_(connecting|connected|disconnected)/] => lambda { |v| Weechat::Server.from_name(v) },
      [/weechat_(highlight|pv)/] => lambda { |v| Weechat::Line.parse(v) },
      [/window_(scrolled|unzooming|unzoomed|zooming|zoomed)/] => lambda { |v| Weechat::Window.from_ptr(v) },
      [/irc_(raw_)?((in)|(out))/] => lambda { |v| Weechat::IRC::Message.parse_message(v) },
      ["irc_ctcp"] => lambda { |v| Weechat::IRC::Message.new(v) },
    }
    public

    # low level callback for signal hooks
    def signal_callback(id, signal, data)
      data = Weechat::Utilities.apply_transformation(signal, data, SignalCallbackTransformations)
      Weechat::Hooks::Signal.find_by_id(id).call(signal, data)
    end

    # low level config callback
    def config_callback(id, option, value)
      ret = Weechat::Hooks::Config.find_by_id(id).call(option, value)
    end

    # low level process callback
    def process_callback(id, command, code, stdout, stderr)
      code = case code
             when Weechat::WEECHAT_HOOK_PROCESS_RUNNING
               :running
             when Weechat::WEECHAT_HOOK_PROCESS_ERROR
               :error
             else
               code
             end

      process = Weechat::Process.find_by_id(id)
      if process.collect?
        process.buffer(stdout, stderr)
        if code == :error || code != :running
          process.call(code, process.stdout, process.stderr)
        end
      else
        process.call(code, stdout, stderr)
      end
    end

    private
    ModifierCallbackTransformations = {
      [/^irc_(in|out)_.+$/] => lambda { |v| Weechat::IRC::Server.from_name(v) },
      ['irc_color_decode', 'irc_color_encode'] => lambda { |v| Weechat.integer_to_bool(v) },
      [/^bar_condition_.+$/]                   => lambda { |v| Weechat::Window.from_ptr(v) },
      ["input_text_content", "input_text_display",
       "input_text_display_with_cursor", "history_add"]       => lambda { |v| Weechat::Buffer.from_ptr(v) },
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
    public

    # low level modifier hook callback
    def modifier_callback(id, modifier, modifier_data, s)
      classes = Weechat::Hook.hook_classes
      modifier_data = Weechat::Utilities.apply_transformation(modifier, modifier_data, ModifierCallbackTransformations)
      modifier_data = [modifier_data] unless modifier_data.is_a?(Array)
      args = modifier_data + [Weechat::Line.parse(s)]

      callback = classes.map {|cls| cls.find_by_id(id)}.compact.first

      ret = callback.call(*args)
      return Weechat::Utilities.apply_transformation(modifier, ret, ModifierCallbackRTransformations).to_s
    end
  end

  class << self
    def get_buffer(buffer = nil)
      case buffer
      when nil
        ""
      when :current
        Weechat::Buffer.current
      else
        buffer
      end
    end

    def exec(command, buffer=nil)
      Weechat.command(buffer.to_s, command)
    end
    alias_method :send_command, :exec
    alias_method :execute, :exec

    def puts(text, buffer = nil)
      buffer = get_buffer(buffer)
      Weechat.print(buffer.to_s, text.to_s)
      nil # to mimic Kernel::puts
    end

    def puts_y(text, line, buffer = nil)
      buffer = get_buffer(buffer)
      Weechat.print_y(text.to_s, line, buffer.to_s)
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

    alias_method :old_bar_update, :bar_update
    def bar_update(name)
      old_bar_update(name.to_s)
    end

    alias_method :old_bar_item_update, :bar_item_update
    def bar_item_update(name)
      old_bar_item_update(name.to_s)
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
require 'weechat/callbacks.rb'
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
require 'weechat/bar.rb'
require 'weechat/irc/server.rb'
require 'weechat/irc/channel.rb'
require 'weechat/irc/message.rb'
require 'weechat/irc/ctcp.rb'
require 'weechat/irc/host.rb'
require 'weechat/irc/identifier.rb'
require 'weechat/irc/user.rb'
require 'weechat/irc/whois.rb'
require 'weechat/infolist.rb'
require 'weechat/color.rb'
require 'weechat/plugin.rb'
require 'weechat/rubyext/string.rb'
require 'weechat/rubyext/boolean.rb'
require 'weechat/rubyext/array.rb'
require 'weechat/rubyext/hash.rb'
require 'weechat/rubyext/integer.rb'
require 'weechat/rubyext/float.rb'
require 'weechat/hooks.rb'
require 'weechat/script.rb'
require 'weechat/script/config.rb'
require 'weechat/option.rb'
require 'weechat/info.rb'
require 'weechat/process.rb'
