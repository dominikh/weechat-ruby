module Weechat
  class Infolist
    def self.parse(type, ptr="", arguments="", requirements = {}, *fields)
      infolist_ptr = Weechat.infolist_get(type.to_s, ptr.to_s, arguments.to_s)
      ret = []
      while Weechat.infolist_next(infolist_ptr) > 0
        h = {}
        not_matching = requirements.any? {|option, value|
          type, value = value
          Weechat.__send__("infolist_#{type}", infolist_ptr, option.to_s) != value
        }

        if not_matching
          next
        else
          str = Weechat.infolist_fields(infolist_ptr)
          str.split(/,/).each do |item|
            type, name = item.split(/:/)
            sname = name.to_sym
            next if !fields.empty? && !fields.include?(sname)
            h[sname] = case type
                             when 'p'
                               Weechat.infolist_pointer(infolist_ptr, name)
                             when 'i'
                               Weechat.infolist_integer(infolist_ptr, name)
                             when 's'
                               Weechat.infolist_string(infolist_ptr, name)
                             when 'b'
                               # FIXME: not exposed to script API yet.
                               # Weechat.infolist_buffer(infolist_ptr, name)
                             when 't'
                               Weechat.infolist_time(infolist_ptr, name)
                             end
          end

          ret << h
        end
      end
      Weechat.infolist_free(infolist_ptr)
      return ret
    end
  end
end
