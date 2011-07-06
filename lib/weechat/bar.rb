module Weechat
  class Bar
    class Item
      include Weechat::Pointer
      extend Weechat::Properties
      extend Weechat::Callbacks

      class << self
        protected
        def inherited(by)
          by.set_instance_variables
        end

        def set_instance_variables
          @transformations = {
            [:plugin] => lambda { |v| Weechat::Plugin.from_ptr(v) },
          }

          @mappings = {}
          @rtransformations = {}
          @settable_properties = %w()

          init_properties
          @type = "bar_item"
        end
        public
      end

      set_instance_variables

      class << self
        def items
          items = []
          Weechat::Infolist.parse("bar_item").each do |item|
            items << Item.find(item[:name])
          end
          items
        end
        alias_method :all, :items

        # finds the Bar::Item with the given name
        # @param [String] name The name of the bar item to find
        # @return [Bar::Item, nil] The found bar item, or nil if none with the given
        #  name was found
        def find(name)
          ptr = Weechat.bar_item_search(name)
          if !ptr.empty?
            from_ptr(ptr)
          else
            nil
          end
        end
        alias_method :from_name, :find
      end # eigenclass

      def build(window)
        ""
      end

      # Creates a new Bar Item, and registers it for use for Bars.
      # @param [String] name The name of the bar item. It should be unique. This
      # is used in the +:items+ option for Bars to display the bar item
      # @yield [window] The callback to generate and update the item
      # @yieldparam [Window, nil] window If the bar this item is placed on is inside a window
      #   (ie the bar's type is +:window+), it will be the window the bar is present on. Otherwise
      #   it will be nil.
      # @yieldreturn [String] The string used to render the item
      def initialize(name, &build_callback)
        build_callback ||= method(:build)
        id = self.class.compute_free_id
        @ptr = Weechat.bar_item_new(name, "bar_build_callback", id.to_s)
        if @ptr.empty?
          raise "Could not create bar item"
        end

        self.class.register_callback(
                                     :build_callback => Callback.new(build_callback),
                                     :ptr            => @ptr
                                     )
      end

      # Updates the bar item
      def update
        Weechat.bar_item_update(name)
      end

      # removes the bar item, it will no longer be able to be used
      # on any Bars
      def delete
        # TODO mark deletion status
        Weechat.bar_item_remove(@ptr)
      end
      alias_method :remove, :delete

      class << self
        def call_build_callback(id, window)
          window = Window.from_ptr(window)
          call_callback(id, :build_callback, window).to_s
        end
      end # eigenclass
    end # Item

    include Weechat::Pointer
    extend Weechat::Properties

    @transformations = {
      [:hidden, :separator] => lambda { |v| Weechat.integer_to_bool(v) },
      [:type] => lambda { |v| [:root, :window][v] },
      [:position] => lambda { |v| [:top, :bottom, :left, :right][v] },
      [:filling_top_bottom, :filling_left_right] => lambda { |v|
        [:horizontal, :vertical, :columns_horizontal, :columns_vertical][v]
      },
      [:color_fg, :color_delim, :color_bg] => lambda { |v| Weechat::Color.new(v) },
      [:bar_window] => lambda { |v| Weechat::Window.from_ptr(v) },
      [:items] => lambda { |v|
        items = v.split(",")
        items.map { |item|
          item = item.split("+")
          item.size == 1 ? item.first : item
        }
      },
    }

    @mappings = {
      :hidden? => :hidden,
      :separator? => :separator,
      :has_separator? => :separator,
    }

    @rtransformations = {
      [:hidden, :separator] => lambda { |v|
        v.to_weechat_config
      },
      [:color_fg, :color_delim, :color_bg] => lambda { |v|
        if v.respond_to?(:name)
          v.name
        else
          v
        end
      },
      [:name, :type, :condition, :position, :filling_top_bottom,
       :filling_left_right, :size, :size_max, :priority] => lambda  { |v| v.to_s},
      [:items] => lambda { |v|
        v.map {|item|
          if item.is_a?(Array)
            item.join("+")
          else
            item.to_s
          end
        }.join(",")
      },
    }

    @settable_properties = %w(name hidden priority conditions position filling_top_bottom
    filling_left_right size size_max color_fg color_delim color_bg separator items)

    init_properties

    class << self
      # Finds the Bar with the given name
      # @param [String] name The name of the bar to find
      # @return [Bar?] The found Bar, or nil if none was found
      def find(name)
        ptr = Weechat.bar_search(name)
        if !ptr.empty?
          from_ptr(ptr)
        else
          nil
        end
      end
      alias_method :from_name, :find
    end # eigenclass

    # Creates a new Bar. Takes many optional arguments, but only +:name+, +:position+ and
    # +:items+ are required
    # @example
    #  Bar.new(:name => "BottomTimeBar", :position => :bottom, :items => ["time"])
    #
    # @param [Hash] opts The options for creating the Bar object
    # @option opts [String] :name gives the name of the url bar. It has to be unique for all url bars
    # @option opts [:top, :bottom, :left, :right] :position The position of the bar
    # @option opts [Array<String>] :items Items that make up the url bar
    #
    # @option opts [:root, :window] :type either +:root+ or +:window+ (default +:root+)
    #   * +:root+ bar displayed once, outside windows
    #   * +:window+ bar displayed in each window
    # @option opts [Boolean] :hidden whether the bar is hidden (default false)
    # @option opts [Integer] :priority not sure... (default 0) TODO find out what this does
    # @option opts [:active, :inactive, :nicklist] :condition  if +:type == :window+, what windows to use them in (default +:active+)
    #   * +:active+ if bar is displayed in active window only
    #   * +:inactive+ if bar is displayed in inactive windows only
    #   * +:nicklist+ if bar is displayed in windows with nicklist
    # @option opts [:horizontal, :vertical, :columns_horizontal, :columns_vertical] :filling_top_bottom how items are filled (default :horizontal)
    #   * +:horizontal+ items are filled horizontally (space after each item)
    #   * +:vertical+ items are filled vertically (new line after each item)
    #   * +:columns_horizontal+ items are filled horizontally, displayed with columns
    #   * +:columns_vertical+ items are filled vertically, displayed with columns
    # @option opts [:horizontal, :vertical, :columns_horizontal, :columns_vertical] :filling_left_right how items are filled (default :horizontal )
    #   * +:horizontal+ items are filled horizontally (space after each item)
    #   * +:vertical+ items are filled vertically (new line after each item)
    #   * +:columns_horizontal+ items are filled horizontally, displayed with columns
    #   * +:columns_vertical+ items are filled vertically, displayed with columns
    # @option opts [Integer] :size bar size in chars, 0 means automatic size (default 0)
    # @option opts [Integer] :size_max max size for bar, 0 means no max size (default 0)
    # @option opts [String] :color_fg color for text in bar (default "black")
    # @option opts [String] :color_delim color for delimiters in bar (default "blue")
    # @option opts [String] :color_bg background color for bar (default "white")
    # @option opts [Boolean] :separator whether bar has separator line with other windows/bars (default false)
    def initialize(opts)
      @name = opts[:name]
      mapped_args = {}
      args_with_defaults = add_defaults_to_args(opts)
      args_with_defaults.each do |key, value|
        mapped_args[key] = self.class.apply_rtransformation(key, value)
      end

      @ptr = Weechat.bar_new(*mapped_args.values_at(:name, :hidden, :priority, :type,
                                                    :condition, :position, :filling_top_bottom,
                                                    :filling_left_right, :size, :size_max,
                                                    :color_fg, :color_delim, :color_bg, :separator,
                                                    :items))
      if @ptr.empty?
        raise "Could not create bar"
      end

    end

    private
    def add_defaults_to_args(args)
      default_args = {
          :type => :root,
          :hidden => false,
          :priority => 0,
          :condition => :active,
          :filling_top_bottom => :horizontal,
          :filling_left_right => :horizontal,
          :size => 0,
          :size_max => 0,
          :color_fg => "black",
          :color_delim => "black",
          :color_bg => "white",
          :separator => false
        }
      result = {}
      default_args.each do |key, value|
        result[key] = default_args[key]
      end
      args.each do |key, value|
        result[key] = value
      end
      result
    end

    public
    # updates the bar
    def update
      Weechat.bar_update(self.name)
    end

    # deletes the bar.
    def delete
      # TODO mark deletion state
      Weechat.bar_remove(@ptr)
    end
    alias_method :remove, :delete
  end # Bar
end # Weechat
