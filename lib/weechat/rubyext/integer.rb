class Integer
  def self.from_weechat_config(v)
    Integer(v)
  end

  def to_weechat_config
    to_s
  end
end
