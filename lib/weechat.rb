require 'pp'

module Weechat
  VERSION = "0.0.1"
  module Helper
    def command_callback(id, buffer, args)
      # TODO this mimics weechat's current behaviour for the C API.
      # sophisticated argument parsing will come, some day.
      Weechat::Command.find_by_id(id).call(Weechat::Buffer.new(buffer), *args.split(" "))
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
  end

  class << self
    def exec(command, buffer=nil)
      Weechat.command(buffer.to_s, command)
    end
    alias_method :send_command, :exec
    alias_method :execute, :exec
  end

  def self.puts(text, buffer = nil)
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

  def self.p(object, buffer = nil)
    self.puts(object.inspect, buffer)
  end

  def self.pp(object, buffer = nil)
    puts(object.pretty_inspect, buffer)
  end

  def self.integer_to_bool(int)
    int == 1 ? true : false
  end

  def self.bool_to_integer(bool)
    bool ? 1 : 0
  end
end

require 'weechat/exceptions.rb'
require 'weechat/utilities.rb'
require 'weechat/pointer.rb'
require 'weechat/hook.rb'
require 'weechat/timer.rb'
require 'weechat/command.rb'
require 'weechat/input.rb'
require 'weechat/buffer.rb'
require 'weechat/server.rb'
require 'weechat/infolist.rb'
require 'weechat/prefix.rb'
require 'weechat/color.rb'
require 'weechat/rubyext/string.rb'
