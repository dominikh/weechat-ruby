class Boolean
  def self.from_weechat_config(v)
    Weechat.integer_to_bool(Weechat.config_string_to_boolean(v))
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
