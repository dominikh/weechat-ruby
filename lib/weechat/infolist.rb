module Weechat
  class Infolist
    def self.parse(type, ptr="", arguments="")
      infolist_ptr = Weechat.infolist_get(type, ptr, arguments)
      ret = []
      while Weechat.infolist_next(infolist_ptr) > 0
        h = { }
        str = Weechat.infolist_fields(infolist_ptr)
        str.split(/,/).each do |item|
          type, name = item.split(/:/)
          h[name.to_sym] = case type
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

        ret.push h
      end
      Weechat.infolist_free(infolist_ptr)
      return ret
    end
  end
end
