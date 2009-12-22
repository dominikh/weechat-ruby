module Weechat
  module Utilities
    def self.format_exception(e)
      prefix = Weechat.prefix("error")

      line1 = e.backtrace[0] + ": " + e.message + " (" + e.class.name + ")"
      backtrace =  "    " + e.backtrace[1..-1].join("\n    ")

      Weechat.puts("#{prefix}error in evaluated call: #{line1}")
      Weechat.puts("#{prefix}#{backtrace}")
    end

    def self.safe_call
      begin
        ret = yield
      rescue => e
        format_exception(e)
        return Weechat::WEECHAT_RC_ERROR
      end
      ret
    end

    def self.evaluate_call
      begin
        yield
      rescue Weechat::Exception::WEECHAT_RC_OK
        return Weechat::WEECHAT_RC_OK
      rescue Weechat::Exception::WEECHAT_RC_OK_EAT
        return Weechat::WEECHAT_RC_OK_EAT
      rescue Weechat::Exception::WEECHAT_RC_ERROR
        return Weechat::WEECHAT_RC_ERROR
      rescue => e
        format_exception(e)
        return Weechat::WEECHAT_RC_ERROR
      end

      return Weechat::WEECHAT_RC_OK
    end

    def self.apply_transformation(property, value, transformations)
      transformation = transformations.find {|properties, transformations|
        properties.any? {|prop|
          case prop
          when Regexp
            prop =~ property.to_s
          when String, Symbol
            prop.to_sym == property.to_sym
          else
            false
          end
        }
      }

      if transformation
        transformation[1].call(value)
      else
        value
      end
    end
  end
end
