module Weechat
  class Script
    class Config
      def initialize(specification)
        @specification = specification
      end

      def __get_config__(option)
        ret = Weechat.config_get_plugin(option)
        if ret.empty?
          @specification[option][1]
        else
          @specification[option][0].from_weechat_config(ret)
        end
      end

      def __set_config__(option, value)
        value = value.respond_to?(:to_weechat_config) ? value.to_weechat_config : value.to_s
        Weechat.config_set_plugin(option, value)
      end

      def method_missing(m, *args)
        m = m.to_s
        if m[-1..-1] != '='
          if @specification.has_key?(m)
            return __get_config__(m)
          end
        else
          if @specification.has_key?(m[0..-2])
            return __set_config__(m[0..-2], *args)
          end
        end

        super
      end
    end

    module Skeleton
      def self.included(other)
        other.__send__ :include, InstanceMethods
        other.__send__ :extend, InstanceMethods
        other.__send__ :extend, ClassMethods
      end

      module ClassMethods
        def script
          {
            :license     => 'unlicensed',
            :version     => '0.0.1',
            :author      => 'Anonymous',
            :description => 'Empty script description',
            :charset     => '',
          }.merge(@script)
        end
      end

      module InstanceMethods
        def weechat_init
          Weechat.register(self.script[:name],
                           self.script[:author],
                           self.script[:version],
                           self.script[:license],
                           self.script[:description],
                           'weechat_script_unload',
                           self.script[:charset])
          if respond_to?(:setup)
            return Weechat::Utilities.evaluate_call { setup }
          end

          return Weechat::WEECHAT_RC_OK
        end

        def weechat_script_unload
          if respond_to?(:teardown)
            return Weechat::Utilities.evaluate_call { teardown }
          end

          return Weechat::WEECHAT_RC_OK
        end
      end
    end

    include Weechat::Pointer
    extend Weechat::Properties

    init_properties

    class << self
      def scripts(plugin = nil)
        Plugin.all.map {|plugin| plugin.scripts}.flatten
      end
      alias_method :all, :scripts
    end

    def initialize(ptr, plugin)
      super(ptr)
      @plugin = plugin
    end

    def get_infolist
      Weechat::Infolist.parse("#{@plugin.name}_script", @ptr)
    end
  end
end
