module Weechat
  # This class provides a wrapper around WeeChat buffers.
  #
  # While each instance of this class only contains the
  # {Weechat::Pointer pointer} of a Buffer, several methods allow
  # {#get_property retrieving} and {#set_property setting} properties,
  # {#display displaying} / {#move moving} / {#close closing} buffers
  # and working with the {#lines lines} and {#text content} of a
  # buffer.
  #
  # == Accessing properties
  # === The lowest level methods
  # ==== With fail checking
  #
  # To get the raw data as returned by the Weechat API, but still
  # applying fail checks, one uses {#get_string_property},
  # {#get_integer_property} and {#get_infolist_property}. Values will
  # be returned as is, without any transformations.
  #   my_buffer.get_string_property("name")          # => "some name"
  #   my_buffer.get_integer_property("lines_hidden") # => 1
  #   my_buffer.get_string_property("foo")           # => Weechat::Buffer::UnknownProperty: foo
  #
  # To set properties, while still applying fail checks, one uses
  # {#set_string_property} (since each value, also numbers, will be
  # turned into strings anyway, we don't need set_integer_property).
  #   my_buffer.set_string_property("name", "new name")
  #   my_buffer.set_string_property("foo", "bar") # => Weechat::Buffer::UnsettableProperty: foo
  #
  #
  # === Without fail checking
  #
  # This is the lowest possible way of accessing properties, since
  # these methods will just call out to the API directly. These
  # methods are {#get_string}, {#get_integer} and {#set}. There is no
  # direct way to get properties returned by infolists other than
  # using {Weechat::Infolist.parse}
  #
  # === Using the abstractional layer
  #
  # The proper way of getting and setting properties is by either
  # using {#get_property} and {#set_property} or by directly accessing
  # attributes. Note that when directly accessing them, one can
  # use query methods, e.g. #lines_hidden? if the property returns
  # true or false.
  #
  # The added benefit, except from cleaner code, is that the methods
  # return proper values. Instead of 0 and 1 it replies false and true
  # (where applicable) and also allows those when setting values.
  # Lists will be represented as arrays, while the low level API would
  # return a comma delimited list.
  #   my_buffer.name          # => "some name"
  #   my_buffer.lines_hidden? # => false
  #   my_buffer.lines_hidden = true
  #
  # WeeChat also uses the setter API for a few operations like
  # updating the read marker or switching to another buffer. While
  # this is possible with the Ruby abstraction, it also provides
  # proper methods for doing so ( {#update_marker}, {#show} ):
  #   my_buffer.update_marker
  #   another_buffer.show
  #
  # == Creating new buffers
  #
  # Using {Buffer.create}, one can also create new buffers which even
  # respond to input and closing using hooks (procs or methods or
  # anything that responds to #call).
  #   Buffer.create("my buffer",
  #     lambda {|b, i|
  #       # work with input
  #     },
  #     lambda {|b|
  #       # respond to the closing of a buffer
  #     }
  #   )
  #
  # == The input line
  #
  # While internally the input line is managed by two properties
  # (`input` and `input_get_unknown_commands`), the Weechat Ruby
  # abstraction uses one instance of the {Input} class per buffer (see
  # {#input}). The content of the input line thus can be read using
  # {Input#text} and set using {Input#text=} (or using the shorthand
  # {#input=}). To turn on/off the receiving of unknown commands, use
  # {Input#get_unknown_commands=}.
  #
  # == List of gettable properties using {#get_property}
  #
  # * plugin
  # * name         -- The name of the buffer
  # * short_name   -- The short name of the buffer
  # * title        -- The title of the buffer
  # * input        -- (Use {Input#text} instead)
  # * number       -- The number (position) of the buffer
  # * num_displayed
  # * notify
  # * lines_hidden -- true if at least one line is hidden (filtered), otherwise false
  # * prefix_max_length
  # * time_for_each_line
  # * text_search
  # * text_search_exact
  # * text_search_found
  #
  # == List of settable properties using {#set_property}
  #
  # * hotlist
  # * unread          -- (Use {#update_marker} instead)
  # * display         -- (Use {#display} instead)
  # * number          -- (Use {#move} instead)
  # * name            -- The name of the buffer
  # * short_name      -- The short name of the buffer
  # * type
  # * notify
  # * title           -- The title of the buffer
  # * time_for_each_line -- Whether to display times or not (also called show_times)
  # * nicklist
  # * nicklist_case_sensitive
  # * nicklist_display_groups
  # * highlight_words -- Sets the words to highlight in the buffer, expects an array
  # * highlight_tags  -- Sets the tags to highlight in the buffer, expects an array
  # * input           -- (Use {Input#text=} instead)
  # * input_get_unknown_commands -- (Use {Input#get_unknown_commands=} instead)
  class Buffer
    include Weechat::Pointer
    # @overload input
    #   @return [Weechat::Input]
    # @overload input=(val)
    #   Sets the content of the input line.
    #
    #   @return [void]
    #   @see Input#text=
    attr_accessor :input

    @callbacks = []

    # A list of all properties that can be retrieved using {#get_string_property}.
    #
    # @private
    KNOWN_STRING_PROPERTIES  = %w(plugin name short_name title input).freeze

    # A list of all properties that can be retrieved using {#get_integer_property}.
    #
    # @private
    KNOWN_INTEGER_PROPERTIES = %w(number num_displayed notify lines_hidden prefix_max_length
    time_for_each_line text_search text_search_exact
    text_search_found).freeze

    # A list of all properties that can be set using {#set_property}.
    #
    # @private
    SETTABLE_PROPERTIES = %w(hotlist unread display number name short_name type notify
    title time_for_each_line nicklist nicklist_case_sensitive nicklist_display_groups
    highlight_words highlight_tags input input_get_unknown_commands).freeze
    # @todo localvar_set_xxx
    # @todo localvar_del_xxx
    # @todo key_bind_xxx
    # @todo key_unbind_xxx

    # The transformation procedures that get applied to values after
    # they've been received using {#get_property}.
    #
    # @private
    TRANSFORMATIONS = {
      [:lines_hidden, :time_for_each_line, :text_search_exact,
       :text_search_found] => lambda {|v| Weechat.integer_to_bool(v) },
      [:highlight_words, :highlight_tags] => lambda {|v| v == "-" ? [] : v.split(",") }
    }

    # The transformation procedures that get applied to values before they
    # are set by {#set_property}.
    #
    # @private
    RTRANSFORMATIONS = {
      [:lines_hidden, :time_for_each_line, :text_search_exact,
       :text_search_found] => lambda {|v| Weechat.bool_to_integer(v) },
      [:unread] => lambda {|v| !v ? nil : 1},
      [:highlight_words, :highlight_tags] => lambda {|v|
        s = v.join(",")
        s.empty? ? "-" : s
      },
    }

    # @private
    MAPPINGS = {
      :lines_hidden?       => :lines_hidden,
      :time_for_each_line? => :time_for_each_line,
      :text_search_exact?  => :text_search_exact,
      :text_search_found?  => :text_search_found,
      :show_times?         => :time_for_each_line,
      :show_times=         => :time_for_each_line=,
    }

    # This exception gets raised whenever one tries to read a property
    # that doesn't exist.
    #
    # @see #get_property
    class UnknownProperty < RuntimeError; end

    # This exception gets raised whenever one tries to set a property
    # that cannot be set.
    #
    # @see #set_property
    class UnsettableProperty < RuntimeError; end

    # This exception gets raised when one tries to create a buffer
    # with the name of an already existing one.
    #
    # @see ::create
    class DuplicateBufferName < RuntimeError; end

    class << self
      # Returns all known properties of buffers.
      #
      # @return [Array<Symbol>] The properties
      def known_properties
        KNOWN_INTEGER_PROPERTIES + KNOWN_STRING_PROPERTIES
      end

      # @return [Buffer]
      # @see #initialize
      def from_ptr(ptr)
        self.new(ptr)
      end

      # Returns a list of all buffers
      #
      # @return [Array<Buffer>]
      def buffers
        buffers = []
        Weechat::Infolist.parse("buffer").each do |buffer|
          buffers << Buffer.new(buffer[:pointer])
        end
        buffers
      end
      alias_method :all, :buffers

      # This method manages all input callbacks, resolving the
      # callback to use by an ID which gets supplied by
      # {Weechat::Helper#input_callback}. This shouldn't be called
      # directly by the user.
      #
      # @return [void]
      # @see .call_close_callback
      # @private
      def call_input_callback(id, buffer, input)
        buffer = Buffer.new(buffer)
        @callbacks[id.to_i][:input_callback].call(buffer, input)
        return Weechat::WEECHAT_RC_OK
      end

      # This method manages all close callbacks, resolving the
      # callback to use by an ID which gets supplied by
      # {Weechat::Helper#close_callback}. This shouldn't be called
      # directly by the user.
      #
      # @return [void]
      # @see .call_input_callback
      # @private
      def call_close_callback(id, buffer)
        buffer = Buffer.new(buffer)
        @callbacks[id.to_i][:close_callback].call(buffer)
        return Weechat::WEECHAT_RC_OK
      end

      # Returns all callbacks
      #
      # @return [Array<Hash{Symbol => String, #call}>] An array of hashes containing
      #   the callbacks and pointers of the buffers to which the callbacks are assigned to
      # @see #input_callback
      # @see #close_callback
      def callbacks
        @callbacks
      end

      # Returns the current buffer.
      #
      # @return [Buffer] The current buffer
      def current
        Buffer.new(Weechat.current_buffer)
      end

      # Creates a new buffer.
      #
      # @param [#to_s] name The name of the new buffer
      # @param [#call] input_callback The callback to be called when something
      #   is entered in the new buffer's input line
      # @param [#call] close_callback The callback to be called when the new buffer
      #   is being closed
      # @example
      #   Buffer.create("my buffer",
      #     lambda {|b, i|
      #       # work with input
      #     },
      #     lambda {|b|
      #       # respond to the closing of a buffer
      #     }
      #   )
      # @return [Buffer] The new buffer
      # @raise [DuplicateBufferName] In case a buffer with that name already exists
      def create(name, input_callback, close_callback)
        @callbacks << {
          :input_callback => input_callback,
          :close_callback => close_callback,
        }
        id = @callbacks.size - 1
        ptr = Weechat.buffer_new(name.to_s, "input_callback", id.to_s, "close_callback", id.to_s)
        if ptr.empty
          raise DuplicateBufferName(name.to_s)
        else
          @callbacks[-1][:ptr] = ptr
          Buffer.new(ptr)
        end
      end
    end

    # this defines all the getter methods for buffers
    self.known_properties.each do |property|
      define_method(property) { get_property(property) }
    end

    # this defined all the setter methods for buffers
    SETTABLE_PROPERTIES.each do |property|
      define_method(property + '=') {|v| set_property(property, v) }
    end

    # this adds a few aliases to make the interface more rubyish
    MAPPINGS.each do |key, value|
      alias_method key, value
    end

    def initialize(ptr)
      super
      @input = Weechat::Input.new(self)
    end

    def input=(val)
      @input.text=(val)
    end

    # Displays the buffer in the current window.
    #
    # @param [Boolean] auto If set to true, the read marker of the currently visible
    #   buffer won't be reset
    # @return [void]
    def display(auto = false)
      auto = auto ? "auto" : 1
      set_property("display", auto)
    end
    alias_method :show, :display

    # Checks if the buffer is valid, that is if the pointer represents an existing buffer.
    #
    # @return [Boolean]
    def valid?
      Buffer.buffers.map{|b|b.pointer}.include?(@ptr)
    end
    alias_method :exist?, :valid?

    # Check if the buffer represents a channel.
    #
    # @return [Boolean]
    def channel?
      # get all servers
      # get all channels of all servers
      # return true of pointer equal
    end

    # Send a command to the current buffer.
    #
    # Note: If the given command does not start with a slash, one will be added.
    #
    # @param [Array<String>] *parts All parts of the command to send
    # @example
    #   my_buffer.command("/whois", "dominikh")
    def command(*parts)
      parts[0][0,0] = '/' unless parts[0][0..0] == '/'
      Weechat.exec(parts.join(" "), self)
    end
    alias_method :send_command, :command
    alias_method :exec, :command
    alias_method :execute, :command

    # Send a text to the buffer. If the buffer represents a channel, the text
    # will be send as a message to the channel.
    #
    # Note: this method will automatically escape a leading slash, if present.
    #
    # @param [Array<String>] *text All parts of the text to send
    def send(*text)
      text[0][0,0] = '/' if text[0][0..0] == '/'
      command(*text.join(" "))
    end
    alias_method :privmsg, :send
    alias_method :say, :send

    # Closes the buffer.
    #
    # Note: After a buffer has been closed, it shouldn't be used anymore as
    # that might lead to segfaults.
    #
    # @return [void]
    def close
      # TODO add check if a buffer is closed, to all methods
      Weechat.buffer_close(@ptr)
      @closed = true
    end

    # Moves the buffer.
    #
    # @param [Number] move The position to move the buffer to
    # @return [Number] The position the buffer was moved to
    def move(n)
      self.number = (n)
    end
    alias_method :move_to, :move

    # Moves the read marker to the bottom
    #
    # @return [void]
    def update_marker
      self.unread = true
    end
    alias_method :update_read_marker, :update_marker

    # Clears the buffer.
    #
    # @return [void]
    def clear
      Weechat.buffer_clear(@ptr)
    end

    # Returns all properties (except from localvars) of the buffer.
    #
    # @return [Hash{Symbol => Object}] The properties
    # @see #get_property
    def to_h
      properties = {}
      Weechat::Infolist.parse("buffer", @ptr).first.each do |key, value|
        properties[key.to_sym] = value
      end
      self.class.known_properties.each {|property|
        properties[property.to_sym] = get_property(property)
      }
      properties
    end

    # Checks if a property can be set.
    #
    # @return [Boolean]
    # @see #valid_property?
    # @see #set_property
    def settable_property?(property)
      property = property.to_s
      SETTABLE_PROPERTIES.include?(property)
    end

    # Sets a property. Transformations, if appropriate, will be applied to the value
    # before setting it. This means that e.g. true and false will be turned into 1 and 0.
    #
    # @raise [UnsettableProperty]
    # @return [String, Integer] The value after if has been transformed
    # @see #set_string_property
    # @see #set
    def set_property(property, v)
      property = property.to_s
      raise UnsettableProperty.new(property) unless settable_property?(property)

      RTRANSFORMATIONS.each do |key, value|
        if key.include?(property.to_sym)
          v = value.call(v)
          break
        end
      end

      set(property, v)
      v
    end

    # Sets a string property on the buffer, not applying any transformations.
    #
    # @return [String] The value
    # @see #set_property
    # @see #set
    def set_string_property(property, v)
      property = property.to_s
      raise UnsettableProperty.new(property) unless settable_property?(property)
      set(property, v)
    end

    # Sets a buffer property, not doing any checks or converions whatsoever.
    #
    # @return [void]
    # @see #set_property
    # @see #set_string_property
    def set(property, value)
      Weechat.buffer_set(@ptr, property.to_s, value.to_s)
    end

    # Get a property. Transformations, if appropriate, will be applied to the value
    # before returning it. This means that e.g. 0 and 1 might be turned into false and true.
    #
    # @raise [UnknownProperty]
    # @return [String, Number, Boolean]
    # @see #get_integer_property
    # @see #get_string_property
    # @see #get_infolist_property
    # @see #set_property
    def get_property(property)
      property = property.to_s
      if KNOWN_INTEGER_PROPERTIES.include?(property)
        v = get_integer_property(property)
      elsif KNOWN_STRING_PROPERTIES.include?(property) or valid_property?(property, :localvar)
        v = get_string_property(property)
      elsif valid_property?(property, :infolist)
        v = get_infolist_property(property)
      else
        raise UnknownProperty.new(property)
      end

      TRANSFORMATIONS.each do |key, value|
        if key.include?(property.to_sym)
          v = value.call(v)
          break
        end
      end
      return v
    end

    # Returns an integer property.
    #
    # @raise [UnknownProperty]
    # @return [Number]
    # @see #get_integer
    # @see #get_property
    # @see #get_string_property
    # @see #get_infolist_property
    def get_integer_property(property)
      property = property.to_s
      raise UnknownProperty.new(property) unless valid_property?(property, :integer)
      get_integer(property)
    end

    # @see #get_integer_property
    # @see #get_string
    # @see #get_property
    def get_integer(property)
      Weechat.buffer_get_integer(@ptr, property.to_s).to_i
    end
    alias_method :buffer_get_integer, :get_integer

    # Returns a string property.
    #
    # @raise [UnknownProperty]
    # @return [String]
    # @see #get_string
    # @see #get_property
    # @see #get_integer_property
    # @see #set_string_property
    def get_string_property(property)
      property = property.to_s
      raise UnknownProperty.new(property) unless valid_property?(property, :string)
      get_string(property)
    end

    # Returns a string property, not doing any checks.
    #
    # @return [String]
    # @see #get_string_property
    # @see #get_property
    # @see #get_integer
    # @see #set_string_property
    def get_string(property)
      Weechat.buffer_get_string(@ptr, property.to_s)
    end
    alias_method :buffer_get_string, :get_string

    # Returns a property obtained by an infolist.
    #
    # @raise [UnknownProperty]
    # @return [String]
    # @see #get_property
    # @see #get_string_property
    # @see #get_integer_property
    def get_infolist_property(property)
      property = property.to_s
      raise UnknownProperty.new(property) unless valid_property?(property, :infolist)
      Weechat::Infolist.parse("buffer", @ptr).first[property.to_sym]
    end

    # Checks if a property is valid. That is, if get_(integer|string|infolist)_property are
    # able to return a value.
    #
    # @param [#to_s] property The name of the property
    # @param [Symbol] type The type of properties to check for.
    #   Can be one of :all, :string, :integer, :localvar or :infolist
    # @return [Boolean]
    # @see #settable_property?
    # @see #get_property
    def valid_property?(property, type = :all)
      property = property.to_s
      case type
      when :all
        valid_property?(property, :string) or
          valid_property?(property, :integer) or
          valid_property?(property, :localvar) or
          valid_property?(property, :infolist)
      when :string
        KNOWN_STRING_PROPERTIES.include?(property) or valid_property?(property, :localvar)
      when :integer
        KNOWN_INTEGER_PROPERTIES.include?(property)
      when :localvar
        property =~ /^localvar_.+$/
      when :infolist
        Weechat::Infolist.parse("buffer", @ptr).first[property.to_sym]
      end
    end

    # method_missing returns buffer local variables.
    #
    # @return [String]
    def method_missing(m, *args)
      if args.empty? && valid_property(m.to_s, :localvar)
        get_property(m.to_s)
      else
        super
      end
    end

    # The input callback assigned to the buffer.
    #
    # @return [#call]
    # @see #close_callback
    # @see .call_input_callback
    def input_callback
      self.class.callbacks.find {|c| c.ptr == @ptr}[:input_callback]
    end

    # The close callback assigned to the buffer.
    #
    # @return [#call]
    # @see #input_callback
    # @see .call_close_callback
    def close_callback
      self.class.callbacks.find {|c| c.ptr == @ptr}[:close_callback]
    end

    # Writes to the buffer.
    #
    # @return [void]
    def print(text)
      Weechat.puts(text, @ptr)
    end
    alias_method :puts, :print

    # Returns an array with all lines of the buffer.
    #
    # @param [Boolean] strip_colors Whether to strip out all color codes
    # @return [Array<String>] The lines
    # @see #text
    def lines(strip_colors = false)
      lines = []
      Weechat::Infolist.parse("buffer_lines", @ptr).each do |line|
        if strip_colors
          line[:prefix].strip_colors!
          line[:message].strip_colors!
        end
        lines << ("%s %s %s" % [line[:date], line[:prefix], line[:message]])
      end

      lines
    end

    # Returns the content of the buffer.
    #
    # @param strip_colors (see Weechat::Buffer#lines)
    # @return [String]
    # @see #lines
    def text(strip_colors = false)
      lines(strip_colors).join("\n")
    end
    alias_method :content, :text

    # Returns the number of lines in the buffer.
    #
    # @return [Number] The number of lines in the buffer
    def size
      # TODO check if there is a property for that
      Weechat::Infolist.parse("buffer_lines", @ptr).size
    end
    alias_method :count, :size
    alias_method :length, :size
  end

  # The core buffer
  Core = Buffer.new("")
end