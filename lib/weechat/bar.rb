module Weechat
  class Bar
    class Item
      include Weechat::Pointer
      extend Weechat::Properties
      extend Weechat::Callbacks

      @transformations = {
        [:plugin] => lambda { |v| Weechat::Plugin.from_ptr(v) },
      }

      @mappings = {}
      @rtransformations = {}
      @settable_properties = %w()

      init_properties
      @type = "bar_item"

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

      def initialize(name, &build_callback)
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
        Weechat.bar_item_update(@name)
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
      mapped_args = {}
      args.each do |key, value|
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

      @name = args[:name]
    end

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
