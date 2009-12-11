class Array
  def self.from_weechat_config(v)
    v.escaped_split(",")
  end

  def to_weechat_config
    map {|entry|
      case entry
      when String
        entry.gsub(/(\\+)?,/) {|m|
          if $1.nil?
            "\\,"
          else
            $1 + $1 + "\\,"
          end
        }
      else
        entry.to_weechat_config
      end
    }.join(",")
  end
end
