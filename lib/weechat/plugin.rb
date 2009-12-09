module Weechat
  # == Gettable properties
  #
  # [filename]    Filename of the plugin
  # [handle]      ?
  # [name]        Name of the plugin
  # [description] Description of the plugin
  # [author]      Author of the plugin
  # [version]     Version of the plugin
  # [license]     Licence of the plugin
  # [charset]     ?
  # [debug?]      ?
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
        if name.nil? or name.empty?
          name = "core"
        end
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

      # Loads a plugin.
      #
      # @return [void]
      def load(name)
        Weechat.exec("/plugin load #{name}")
      end

      # Reloads all plugins.
      #
      # Note: This will not reload the ruby plugin.
      #
      # @return [Array<Plugin>] All plugins that have been reloaded.
      def reload_all
        plugins = all.select{|plugin| plugin.name != "ruby"}
        plugins.each {|plugin| plugin.reload}
      end
    end

    def name
      Weechat.plugin_get_name(@ptr)
    end

    # Unloads the plugin.
    #
    # @param [Boolean] force If the plugin to be unloaded is "ruby",
    #   +force+ has to be true.
    # @return [Boolean] true if we attempted to unload the plugin
    def unload(force = false)
      if name == "ruby" and !force
        Weechat.puts "Won't unload the ruby plugin unless you force it."
        false
      else
        Weechat.exec("/plugin unload #{name}")
        true
      end
    end

    # Reload the plugin.
    #
    # @param [Boolean] force If the plugin to be reloaded is "ruby", +force+ has to be true.
    # @return [Boolean] true if we attempted to reload the plugin
    def reload(force = false)
      if name == "ruby" and !force
        Weechat.puts "Won't reload the ruby plugin unless you force it."
      else
        Weechat.exec("/plugin reload #{name}")
      end
    end

    # Returns an array of all scripts loaded by this plugin.
    #
    # @return [Array<Script>]
    def scripts
      scripts = []
      Infolist.parse("#{name}_script").each do |script|
        scripts << Script.new(script[:pointer], self)
      end
      scripts
    end
  end
end
