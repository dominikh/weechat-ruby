module Weechat
  # This class encapsulates lines like they're printed in WeeChat.
  #
  # A line usually consists of a prefix (doesn't have to) and a text.
  # One can access both parts individually, or call methods on both
  # combined, which means that the method will be first called on the
  # prefix and then on the text part.
  class Line
    class << self
      def parse(line)
        parts = line.split("\t")
        case parts.size
        when 0
          parts = ["", ""]
        when 1
          parts.unshift ""
        when 2
        else
          parts = [parts[0], parts[1..-1].join("\t")]
        end

        new(*parts)
      end

      def from_hash(h)
        prefix  = h.delete(:prefix)
        message = h.delete(:message)
        new(prefix, message, h)
      end
    end

    %w(y date date_printed str_time tags_count tags displayed highlight last_read_line).each do |prop|
      define_method(prop) { details[prop] }
      define_method("#{prop}=") {|v| details[prop] = v }
    end

    attr_accessor :prefix
    attr_accessor :message
    attr_reader   :details
    def initialize(prefix, message, details = {})
      @prefix, @message, @details = prefix, message, details
    end

    def to_s
      join("\t")
    end

    def join(delimiter)
      [prefix.empty? ? nil : prefix, message].compact.join(delimiter)
    end

    def method_missing(m, *args)
      rets = []
      [prefix, message].each do |var|
        rets << var.__send__(m, *args) rescue var
      end
      [rets[0].empty? ? nil : rets[0], rets[1]].compact.join("\t")
    end
  end
end
