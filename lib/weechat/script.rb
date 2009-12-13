module Weechat
  class Script
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

        def config
          @config || Weechat::Script::Config.new({})
        end
      end

      module InstanceMethods
        def weechat_init
          ret = Weechat.register(self.script[:name],
                                 self.script[:author],
                                 self.script[:version],
                                 self.script[:license],
                                 self.script[:description],
                                 'weechat_script_unload',
                                 self.script[:charset])
          if Weechat.integer_to_bool(ret)
            self.config.set_script_name!(self.script[:name])
            self.config.init!
            if respond_to?(:setup)
              return Weechat::Utilities.evaluate_call { setup }
            end

            return Weechat::WEECHAT_RC_OK
          end
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
