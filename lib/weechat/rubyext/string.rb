class String
  def self.from_weechat_config(v)
    v
  end

  def to_weechat_config
    self
  end

  # Checks if the string represents a valid channel name
  #
  # @return [Boolean]
  def channel?
    Weechat.info_get("irc_is_channel", self) == '1' ? true : false
  end

  # Returns the nick part of a banmask
  #
  # @return [String] The nick
  def nick
    Weechat.info_get("irc_nick_from_host", self)
  end

  # Removes or replaces all color codes
  #
  # @param [String] replacement The replacement string for color codes
  # @return [String] A new string without color codes
  def remove_color(replacement='')
    Weechat.string_remove_color(self, replacement)
  end
  alias_method :remove_colors, :remove_color
  alias_method :strip_colors, :remove_color

  # Same as {#remove_color} but changing the string in place.
  #
  # @param (see String#remove_color)
  # @return [String] self
  def remove_color!(replacement='')
    self.replace(remove_color(replacement))
  end
  alias_method :remove_colors!, :remove_color!
  alias_method :strip_colors!, :remove_color!

  def escaped_split(split_char, escape_char = "\\")
    parts = []
    escaping = false
    cur = ""

    self.split('').each do |char|
      if char == escape_char
        if escaping
          cur << char
          escaping = false
        else
          escaping = true
        end
      elsif char == split_char
        if !escaping
          parts << cur
          cur = ""
        else
          cur << char
          escaping = false
        end
      else
        if escaping
          cur << escape_char
          escaping = false
        end
        cur << char
      end
    end
    parts << cur
    if parts.size == 1 && parts[0].empty?
      []
    else
      parts
    end
  end

  # @author Loren Segal
  def shell_split
    out = [""]
    state = :none
    escape_next = false
    quote = ""
    strip.split(//).each do |char|
      case state
      when :none, :space
        case char
        when /\s/
          out << "" unless state == :space
          state = :space
          escape_next = false
        when "\\"
          if escape_next
            out.last << char
            escape_next = false
          else
            escape_next = true
          end
        when '"', "'"
          if escape_next
            out.last << char
            escape_next = false
          else
            state = char
            quote = ""
          end
        else
          state = :none
          out.last << char
          escape_next = false
        end
      when '"', "'"
        case char
        when '"', "'"
          if escape_next
            quote << char
            escape_next = false
          elsif char == state
            out.last << quote
            state = :none
          else
            quote << char
          end
        when '\\'
          if escape_next
            quote << char
            escape_next = false
          else
            escape_next = true
          end
        else
          quote << char
          escape_next = false
        end
      end
    end
    out
  end

  # Downcase a string (nickname) according to RFC 1459.
  #
  # @return [String]
  def irc_downcase
    downcase.tr("[]\\~", "{}|^")
  end

  # Same as #irc_downcase, but modifying the string in place.
  #
  # @return [String] self
  def irc_downcase!
    replace(irc_downcase)
  end

  # Upcases a string (nickname) according to RFC 1459.
  #
  # @return [String]
  def irc_upcase
    upcase.tr("{}|^", "[]\\~")
  end

  # Same as #irc_upcase, but modifying the string in place.
  #
  # @return [String] self
  def irc_upcase!
    replace(irc_upcase)
  end
end
