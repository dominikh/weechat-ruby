module Weechat
  # == Gettable properties
  #
  # [filename]
  # [handle]
  # [name]
  # [description]
  # [author]
  # [version]
  # [license]
  # [charset]
  # [debug?]
  class Plugin
    include Weechat::Pointer
    extend Weechat::Properties

    @mappings = {
      :licence => :license,
      :debug?  => :debug,
    }

    @transformations = {
      [:debug] => lambda {|v| Weechat.integer_to_bool(v) },
    }

    init_properties

    class << self
      def find_by_name(name)
        plugins.find {|plugin| plugin.name == name}
      end
      alias_method :find, :find_by_name

      def plugins
        plugins = []
        Weechat::Infolist.parse("plugin").each do |plugin|
          plugins << Plugin.new(plugin[:pointer])
        end
        plugins
      end
      alias_method :all, :plugins
    end

    def name
      Weechat.plugin_get_name(@ptr)
    end
  end
end
