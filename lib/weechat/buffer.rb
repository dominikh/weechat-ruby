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
  # * notify       -- The buffer's notify level. Can be :never, :highlights, :messages and :always
  # * lines_hidden -- true if at least one line is hidden (filtered), otherwise false
  # * prefix_max_length
  # * time_for_each_line -- true if timestamps are shown, false otherwise (also called show_times?)
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
  # * notify          -- The buffer's notify level. Can be :never, :highlights, :messages and :everything
  # * title           -- The title of the buffer
  # * time_for_each_line -- Whether to display times or not (also called show_times)
  # * nicklist
  # * nicklist_case_sensitive
  # * nicklist_display_groups
  # * highlight_words -- Sets the words to highlight in the buffer, expects an array
  # * highlight_tags  -- Sets the tags to highlight in the buffer, expects an array
  # * input           -- (Use {Input#text=} instead)
  # * input_get_unknown_commands -- (Use {Input#get_unknown_commands=} instead)
  #
  # === Notify levels
  #
  # * :never      -- Don't notify at all
  # * :highlights -- Only notify on highlights
  # * :messages   -- Notify on highlights and messages
  # * :everything -- Notify on everything
  #
  # @see http://www.weechat.org/files/doc/stable/weechat_plugin_api.en.html#buffers The WeeChat Buffer API
  class Buffer
    include Weechat::Pointer
    extend Weechat::Properties

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
    @known_string_properties  = %w(plugin name short_name title input).freeze

    # A list of all properties that can be retrieved using {#get_integer_property}.
    #
    # @private
    @known_integer_properties = %w(number num_displayed notify lines_hidden prefix_max_length
    time_for_each_line text_search text_search_exact
    text_search_found).freeze

    # A list of all properties that can be set using {#set_property}.
    #
    # @private
    @settable_properties = %w(hotlist unread display number name short_name type notify
    title time_for_each_line nicklist nicklist_case_sensitive nicklist_display_groups
    highlight_words highlight_tags input input_get_unknown_commands).freeze
    # @todo localvar_set_xxx
    # @todo localvar_del_xxx

    NOTIFY_LEVELS = [:never, :highlights, :messages, :always]

    # The transformation procedures that get applied to values after
    # they've been received using {#get_property}.
    #
    # @private
    @transformations = {
      [:lines_hidden, :time_for_each_line, :text_search_exact,
       :text_search_found] => lambda {|v| Weechat.integer_to_bool(v) },
      [:highlight_words, :highlight_tags] => lambda {|v| v == "-" ? [] : v.split(",") },
      [:notify] => lambda {|v| NOTIFY_LEVELS[v] },
    }

    # The transformation procedures that get applied to values before they
    # are set by {#set_property}.
    #
    # @private
    @rtransformations = {
      [:lines_hidden, :time_for_each_line, :text_search_exact,
       :text_search_found] => lambda {|v| Weechat.bool_to_integer(v) },
      [:unread] => lambda {|v| !v ? nil : 1},
      [:highlight_words, :highlight_tags] => lambda {|v|
        s = v.join(",")
        s.empty? ? "-" : s
      },
      [:notify] => lambda {|v| NOTIFY_LEVELS.index(v) },
    }

    # @private
    @mappings = {
      :lines_hidden?       => :lines_hidden,
      :time_for_each_line? => :time_for_each_line,
      :text_search_exact?  => :text_search_exact,
      :text_search_found?  => :text_search_found,
      :show_times?         => :time_for_each_line,
      :show_times=         => :time_for_each_line=,
      :position            => :number,
      :position=           => :number=,
    }

    init_properties

    class << self
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

      # Finds a buffer by its name and its plugin.
      #
      # @param [String] name The name of the buffer to find
      # @param [String] plugin The plugin of the buffer to find
      # @return [Buffer, nil] An existing buffer or nil if non was found.
      def find_by_name(name, plugin = "ruby")
        ptr = Weechat.buffer_search(plugin, name)
        if ptr == ""
          nil
        else
          Buffer.new(ptr)
        end
      end
      alias_method :find, :find_by_name

      # Returns all buffers with a certain name
      #
      # @param [String, Regexp] pattern The name of the buffers to find or a regular expression
      # @param [Hash{Symbol => Object}] properties A hash with property => value pairs, defining requirements
      #   for the found buffers.
      # @see .find_by_name
      # @return [Array<Buffer>]
      def search(pattern, properties={})
        if pattern.is_a? String
          pattern = Regexp.new("^#{pattern}$")
        end

        Weechat::Infolist.parse("buffer").select {|h|
          h[:name] =~ pattern
        }.map {|h|
          Buffer.new(h[:pointer])
        }.select {|b|
          properties.all? {|key, value|
            b.__send__(key) == value
          }
        }
      end

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
      # @raise [Exception::DuplicateBufferName] In case a buffer with that name already exists
      def create(name, input_callback, close_callback)
        @callbacks << {
          :input_callback => input_callback,
          :close_callback => close_callback,
        }
        id = @callbacks.size - 1
        ptr = Weechat.buffer_new(name.to_s, "input_callback", id.to_s, "close_callback", id.to_s)
        if ptr.empty?
          raise Exception::DuplicateBufferName(name.to_s)
        else
          @callbacks[-1][:ptr] = ptr
          Buffer.new(ptr)
        end
      end
    end

    def initialize(ptr)
      super
      @input = Weechat::Input.new(self)
      @keybinds = {}
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
    # @return [String] The whole command as sent to the buffer
    # @example
    #   my_buffer.command("/whois", "dominikh")
    def command(*parts)
      parts[0][0,0] = '/' unless parts[0][0..0] == '/'
      line = parts.join(" ")
      Weechat.exec(line, self)
      line
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
    # @return [String] The whole string as sent to the buffer
    def send(*text)
      text[0][0,0] = '/' if text[0][0..0] == '/'
      line = text.join(" ")
      command(line)
      line
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

    # Returns the callbacks assigned to the buffer.
    #
    # @return (see Weechat::Buffer.callbacks)
    # @private
    def callbacks
      self.class.callbacks.find {|c| c.ptr == @ptr}
    end

    # The input callback assigned to the buffer.
    #
    # @return [#call]
    # @see #close_callback
    # @see .call_input_callback
    def input_callback
      callbacks[:input_callback]
    end

    # The close callback assigned to the buffer.
    #
    # @return [#call]
    # @see #input_callback
    # @see .call_close_callback
    def close_callback
      callbacks[:close_callback]
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

    def inspect
      sprintf "#<%s:0x%x @ptr=%p>", self.class, object_id << 1, @ptr
    end

    # Bind keys to a command.
    #
    # @param [Array<String>] keys An array of keys which will be used to build a keychain
    # @param [String, Command] command The command to execute when the keys are being pressed
    # @return [String] The keychain
    # @see #unbind_keys
    def bind_keys(keys, command)
      keychain = keys.join("-")
      if command.is_a? Command
        command = command.command
      end
      set("key_bind_#{keychain}", command)
      @keybinds[keys] = command
      keychain
    end

    # Unbind keys.
    #
    # @param[Array<String>] keys An array of keys which will be used to build a keychain
    # @return [String] The command that was assigned to the key bind
    # @see #bind_keys
    def unbind_keys(keys)
      keychain = keys.join("-")
      set("key_unbind_#{keychain}")
      @keybinds.delete keys
    end

    # Returns all key binds
    #
    # @return [Hash{String => String}] A hash with keychain => command assignments
    def key_binds
      @keybinds
    end
  end

  # The core buffer
  Core = Buffer.new("")
end
