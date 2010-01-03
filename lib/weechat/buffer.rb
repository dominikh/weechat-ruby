module Weechat
  # This class provides a wrapper around WeeChat buffers.
  #
  # == Creating new buffers
  #
  # Using {Buffer.new}, one can create new buffers which even
  # respond to input and closing using hooks (procs or methods or
  # anything that responds to #call).
  #   Buffer.new("my buffer",
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
  # (+input+ and +input_get_unknown_commands+), the WeeChat Ruby
  # abstraction uses one instance of the {Input} class per buffer (see
  # {#input}). The content of the input line thus can be read using
  # {Input#text} and set using {Input#text=} (or using the shorthand
  # {#input=}). To turn on/off the receiving of unknown commands, use
  # {Input#get_unknown_commands=}.
  #
  # == Key binds
  #
  # Buffer local key binds can be set/unset using {#bind_keys} and
  # {#unbind_keys}. Note, however, that key binds can only invoke
  # commands, not callbacks (you can, however, pass in existing
  # {Command} instances).
  #
  # == Closed buffers
  #
  # The library is *NOT* doing any checks if the pointer points at a
  # valid/still existing buffer. That means, if you do not take care
  # of this yourself (by keeping your variables up to date or calling
  # {#valid?} yourself), you might risk crashes.
  #
  # == List of getters
  #
  # [plugin]             The plugin which created the buffer
  # [name]               The name of the buffer
  # [short_name]         The short name of the buffer
  # [title]              The title of the buffer
  # [number]             The number (position) of the buffer
  # [num_displayed]      How many windows are displaying this buffer
  # [notify]             The buffer's notify level. Can be +:never+, +:highlights+, +:messages+ and +:always+
  # [lines_hidden?]      true if at least one line is hidden (filtered), otherwise false
  # [prefix_max_length]  "max length for prefix align"
  # [show_times?]        true if timestamps are shown, false otherwise (also called show_times?)
  # [text_search]        The type of search. Can be +:none+, +:backward+ and +:forward+
  # [text_search_exact?] true if search is case sensitive
  # [text_search_found?] true if text was found, false otherwise
  # [text_search_input]  The content of the input buffer before the search was started
  # [active?]            Whether this is the current buffer
  # [highlight_words]    An array of words that trigger highlighting
  # [highlight_tags]     An array of tags that trigger highlighting
  # [type]               The type of the buffer, can be either +:formatted+ or +:free+
  #
  # == List of gettable properties using the infolist
  #
  # :print_hooks_enabled=>1,
  # :first_line_not_read=>0,
  # :prefix_max_length=>0,
  # :nicklist_case_sensitive=>0,
  # :nicklist_display_groups=>1,
  #
  #
  #
  # == List of setters
  #
  # [hotlist]                 (not implemented yet)
  # [name]                    The name of the buffer
  # [short_name]              The short name of the buffer
  # [type]                    The type of the buffer, can be either +:formatted+ or +:free+
  # [notify]                  The buffer's notify level. Can be +:never+, +:highlights+, +:messages+ and +:everything+
  # [title]                   The title of the buffer
  # [show_times]              Whether to display times or not
  # [nicklist]                (not implemented yet)
  # [nicklist_case_sensitive] (not implemented yet)
  # [nicklist_display_groups] (not implemented yet)
  # [highlight_words]         The words to highlight in the buffer, expects an array
  # [highlight_tags]          The tags to highlight in the buffer, expects an array
  # [input]                   Sets the content of the input line (See {Input#text=})
  #
  # === Notify levels
  #
  # [:never]      Don't notify at all
  # [:highlights] Only notify on highlights
  # [:messages]   Notify on highlights and messages
  # [:everything] Notify on everything
  #
  # @see http://www.weechat.org/files/doc/stable/weechat_plugin_api.en.html#buffers The WeeChat Buffer API
  class Buffer
    include Weechat::Pointer
    extend Weechat::Properties
    extend Weechat::Callbacks

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

    NOTIFY_LEVELS = [:never, :highlights, :messages, :always].freeze

    # The transformation procedures that get applied to values after
    # they've been received using {#get_property}.
    #
    # @private
    @transformations = {
      [:lines_hidden, :time_for_each_line, :text_search_exact,
       :text_search_found, :current_buffer] => lambda {|v| Weechat.integer_to_bool(v) },
      [:highlight_words, :highlight_tags] => lambda {|v| v == "-" ? [] : v.split(",") },
      [:notify] => lambda {|v| NOTIFY_LEVELS[v] },
      [:text_search] => lambda {|v| [:none, :backward, :foward][v] },
      [:type] => lambda {|v| [:formatted, :free][v]},
      [:plugin] => lambda {|v| Weechat::Plugin.from_ptr(v)},
    }.freeze

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
      [:notify] => lambda {|v|
        i = NOTIFY_LEVELS.index(v)
        i or raise Exception::InvalidPropertyValue, v.to_s
      },
      [:type] => lambda {|v|
        v = v.to_s
        raise Exception::InvalidPropertyValue, v if !["formatted", "free"].include?(v)
        v
      },
    }.freeze

    # @private
    @mappings = {
      :lines_hidden?       => :lines_hidden,
      :time_for_each_line? => :time_for_each_line,
      :show_times?         => :time_for_each_line,
      :show_times=         => :time_for_each_line=,
      :text_search_exact?  => :text_search_exact,
      :text_search_found?  => :text_search_found,
      :position            => :number,
      :position=           => :number=,
      :active?             => :current_buffer,
      :current?            => :current_buffer,
    }.freeze

    init_properties

    class << self
      # Finds a buffer by its name and its plugin.
      #
      # @param [String] name The name of the buffer to find
      # @param [String, Plugin] plugin The plugin of the buffer to find
      # @return [Buffer, nil] An existing buffer or nil if non was found.
      def find(name, plugin = "ruby")
        plugin = case plugin
                 when Plugin
                   plugin.name
                 else
                   plugin.to_s
                 end
        ptr = Weechat.buffer_search(plugin, name)
        if ptr == ""
          nil
        else
          Buffer.from_ptr(ptr)
        end
      end

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

        Weechat::Infolist.parse("buffer", "", "", properties, :name, :pointer).select {|h|
          h[:name] =~ pattern
        }.map {|h|
          Buffer.from_ptr(h[:pointer])
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
        buffer = Buffer.from_ptr(buffer)
        call_callback(id, :input_callback, buffer, input)
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
        buffer = Buffer.from_ptr(buffer)
        call_callback(id, :close_callback, buffer)
      end

      # Returns the current buffer.
      #
      # @return [Buffer] The current buffer
      def current
        Buffer.from_ptr(Weechat.current_buffer)
      end

      def from_ptr(ptr)
        o = super
        o.instance_variable_set(:@input, Weechat::Input.new(o))
        o.instance_variable_set(:@keybinds, {})
        o
      end
    end


    # @overload input
    #   @return [Weechat::Input]
    # @overload input=(val)
    #   Sets the content of the input line.
    #
    #   @return [void]
    #   @see Input#text=
    attr_accessor :input

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
    def initialize(name, input_callback, close_callback)
      id = self.class.compute_free_id

      @ptr = Weechat.buffer_new(name.to_s, "input_callback", id.to_s, "close_callback", id.to_s)
      if @ptr.empty?
        raise Exception::DuplicateBufferName, name.to_s
      end

      self.class.register_callback(
                        :input_callback => EvaluatedCallback.new(input_callback),
                        :close_callback => EvaluatedCallback.new(close_callback),
                        :ptr            => @ptr
                                   )

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
      Buffer.all.map{|b|b.pointer}.include?(@ptr)
    end
    alias_method :exist?, :valid?

    # Check if the buffer represents a channel.
    #
    # @return [Boolean]
    def channel?
      self.localvar_type == "channel"
    end

    # Returns the channel associated with the buffer.
    #
    # @raise [Exception::NotAChannel]
    # @return [IRC::Channel]
    def channel
      IRC::Channel.new(self)
    end

    def server
      return nil unless ["core", "irc"].include? self.plugin.name
      parts = self.name.split(".")
      name1, name2 = parts[0], parts[1..-1].join(",")

      server = begin
                 IRC::Server.from_name(name1)
               rescue Exception::UnknownServer
                 begin
                   raise Exception::UnknownServer if name2.empty?
                   IRC::Server.from_name(name2)
                 rescue Exception::UnknownServer
                   nil
                 end
               end
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
      Weechat.exec(line)
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
    # @return [Array<Line>] The lines
    # @see #text
    def lines(strip_colors = false)
      lines = []
      Weechat::Infolist.parse("buffer_lines", @ptr).each do |line|
        line = Weechat::Line.from_hash(line)
        if strip_colors
          line.prefix.strip_colors!
          line.message.strip_colors!
        end
        lines << line
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

    # Bind keys to a command.
    #
    # @param [Array<String>] keys An array of keys which will be used to build a keychain
    # @param [String, Command] command The command to execute when the keys are being pressed
    # @return [String] The keychain
    # @see #unbind_keys
    def bind_keys(*args)
      keys = args[0..-2]
      command = args[-1]

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
    def unbind_keys(*keys)
      keychain = keys.join("-")
      set("key_unbind_#{keychain}", "")
      @keybinds.delete keys
    end

    # Returns all key binds
    #
    # @return [Hash{String => String}] A hash with keychain => command assignments
    def key_binds
      @keybinds
    end

    # Returns all windows that are displaying this buffer.
    #
    # @return [Array<Window>]
    def windows
      Window.all.select {|window| window.buffer == self }
    end
  end

  # The core buffer
  Core = Buffer.from_ptr("")
end
