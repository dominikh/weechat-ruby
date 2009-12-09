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
        new(*line.split("\t"))
      end
    end

    attr_accessor :prefix
    attr_accessor :text
    def initialize(prefix, text)
      @prefix, @text = prefix, text
    end

    def to_s
      [@prefix, @text].join("\t")
    end

    def method_missing(m, *args)
      rets = []
      [@prefix, @text].each do |var|
        rets << var.__send__(m, *args) rescue var
      end
      rets.compact.join("\t")
    end
  end
end
