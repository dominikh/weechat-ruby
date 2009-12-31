require 'json'
class Hash
  def to_weechat_config
    to_json
  end

  def self.from_weechat_config(v)
    JSON.load(v)
  end
end
