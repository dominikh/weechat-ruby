module Weechat
  class Bar
    class Item
      include Weechat::Pointer
      extend Weechat::Properties
      extend Weechat::Callbacks

      class << self
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

      def update
        Weechat.bar_item_update(name)
      end

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

    def initialize(args = {})
      @name = args[:name]
      mapped_args = {}
      args_with_defaults = add_defaults_to_args(args)
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
    def update
      Weechat.bar_update(self.name)
    end

    def delete
      # TODO mark deletion state
      Weechat.bar_remove(@ptr)
    end
    alias_method :remove, :delete
  end # Bar
end # Weechat
