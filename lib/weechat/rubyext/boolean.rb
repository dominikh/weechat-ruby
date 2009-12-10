class Boolean
  def self.from_weechat_config(v)
    v == "on" ? true : false
  end
end

class TrueClass
  def to_weechat_config
    "on"
  end
end

class FalseClass
  def to_weechat_config
    "off"
  end
end
