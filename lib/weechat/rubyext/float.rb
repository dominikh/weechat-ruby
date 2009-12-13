class Float
  def self.from_weechat_config(v)
    Float(v)
  end

  def to_weechat_config
    to_s
  end
end
