module Weechat
  class << self
    alias_method :old_prefix, :prefix
    def prefix(name)
      prefix = Weechat.old_prefix(name)
      prefix.empty? ? nil : prefix
    end
    alias_method :get_prefix, :prefix
  end
end
