module Weechat
  class Script
    class Config
      def initialize(specification)
        @specification = specification
      end

      # Resets all options to their default.
      #
      # @return [void]
      def reset!
        clear!
        populate!
      end

      # Unsets all options.
      #
      # @return [void]
      def clear!
        @specification.keys.each {|key| unset!(key)}
      end

      # This will set the default values for all unset options.
      #
      # @return [void]
      def populate!
        @specification.each do |key, value|
          if not set?(key)
            set!(key, value[1])
          end
        end
      end

      # Checks if an option is set.
      #
      # @param [#to_s] option
      # @return [Boolean]
      def set?(option)
        Weechat.integer_to_bool(Weechat.config_is_set_plugin(option.to_s))
      end

      # Unsets an option.
      #
      # @param [#to_s] The option to unset
      # @return [Weechat::CONFIG_OPTION_UNSET_OK_NO_RESET,
      #   Weechat::CONFIG_OPTION_UNSET_RESET,
      #   Weechat::CONFIG_OPTION_UNSET_REMOVED,
      #   Weechat::CONFIG_OPTION_UNSET_ERROR] Integer denoting in how
      #   far unsetting the option worked.
      # @see http://www.weechat.org/files/doc/stable/weechat_plugin_api.en.html#_weechat_config_unset_plugin
      def unset!(option)
        Weechat.config_unset_plugin(option.to_s)
      end

      # Returns an option. If it isn't set, return the default value.
      #
      # @param [#to_s] option
      # @return [Object]
      def get!(option)
        case ret = __get(option)
        when true, false, nil
          ret
        else
          Option.new(self, option)
        end
      end

      def __get(option)
        if set?(option)
          return @specification[option][0].from_weechat_config(Weechat.config_get_plugin(option))
        else
          return @specification[option][1]
        end
      end

      # Sets the value of an option.
      #
      # @param [#to_s] option
      # @param [#to_weechat_config, #to_s] value
      # @return [Weechat::CONFIG_OPTION_SET_OK_CHANGED,
      #   Weechat::CONFIG_OPTION_SET_OK_SAME_VALUE,
      #   Weechat::CONFIG_OPTION_SET_OPTION_NOT_FOUND,
      #   Weechat::CONFIG_OPTION_SET_ERROR] Integer denoting in how
      #   far setting the option worked.
      # @see http://www.weechat.org/files/doc/stable/weechat_plugin_api.en.html#_weechat_config_set_plugin
      def set!(option, value, freeze = false)
        value = value.to_weechat_config
        Weechat.config_set_plugin(option.to_s, value)
        if freeze
          Option.options.each do |opt|
            if opt[0..1] == [self, option]
              opt[2].__freeze__
            end
          end
        end
      end

      def method_missing(m, *args)
        m = m.to_s
        if m[-1..-1] != '='
          if @specification.has_key?(m)
            return get!(m)
          end
        else
          if @specification.has_key?(m[0..-2])
            return set!(m[0..-2], args[0], true)
          end
        end

        super
      end
    end
  end
end
