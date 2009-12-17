require 'yaml'
class Object
  def to_weechat_config
    to_yaml
  end

  def self.from_weechat_config(v)
    YAML.load(v)
  end

  alias_method :__class__, :class
end
