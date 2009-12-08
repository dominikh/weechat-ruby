module Weechat
  module Properties
    module ClassMethods
      # Returns all known properties.
      #
      # @return [Array<Symbol>] The properties
      def known_properties
        @known_integer_properties + @known_string_properties
      end

      def known_integer_properties
        @known_integer_properties
      end

      def known_string_properties
        @known_string_properties
      end

      def settable_properties
        @settable_properties
      end

      def transformations
        @transformations
      end

      def rtransformations
        @rtransformations
      end

      def mappings
        @mappings
      end

      def type
        @type
      end

      def init_properties
        @known_string_properties  ||= [].freeze
        @known_integer_properties ||= [].freeze
        @settable_properties      ||= [].freeze
        @transformations          ||= {}.freeze
        @rtransformations         ||= {}.freeze
        @mappings                 ||= {}.freeze

        @type = self.name.downcase.split("::").last

        # this defines all the getter methods
        known_properties.each do |property|
          define_method(property) { get_property(property) }
        end

        # this defined all the setter methods
        @settable_properties.each do |property|
          define_method(property + '=') {|v| set_property(property, v, true) }
        end

        # this adds a few aliases to make interfaces more rubyish
        @mappings.each do |key, value|
          if respond_to?(value)
            # it is a string/integer property
            alias_method key, value
          else
            # it is an infolist property
            define_method(key) do |*args|
              __send__(value, *args)
            end
          end

        end

        InstanceMethods.alias_methods(@type)
        include InstanceMethods
      end

      def apply_transformation(property, value)
        Utilities.apply_transformation(property, value, @transformations)
      end
    end

    module InstanceMethods
      # Get a property. Transformations, if appropriate, will be applied to the value
      # before returning it. This means that e.g. 0 and 1 might be turned into false and true.
      #
      # @raise [Exception::UnknownProperty]
      # @return [String, Number, Boolean]
      # @see #get_integer_property
      # @see #get_string_property
      # @see #get_infolist_property
      # @see #set_property
      def get_property(property)
        raise Exception::UnknownProperty.new(property) unless valid_property?(property)
        Property.new(self, property)
      end

      # @private
      def __get_property(property)
        property = property.to_s
        if valid_property?(property, :integer)
          v = get_integer_property(property)
        elsif valid_property?(property, :string)
          v = get_string_property(property)
        elsif valid_property?(property, :infolist)
          v = get_infolist_property(property)
        else
          raise Exception::UnknownProperty.new(property)
        end

        return self.class.apply_transformation(property, v)
      end

      # Returns an integer property.
      #
      # @raise [Exception::UnknownProperty]
      # @return [Number]
      # @see #get_integer
      # @see #get_property
      # @see #get_string_property
      # @see #get_infolist_property
      def get_integer_property(property)
        property = property.to_s
        raise Exception::UnknownProperty.new(property) unless valid_property?(property, :integer)
        get_integer(property)
      end

      # Returns an integer property, not doing any checks.
      #
      # @return [Number]
      # @see #get_integer_property
      # @see #get_string
      # @see #get_property
      def get_integer(property)
        Weechat.__send__("#{self.class.type}_get_integer", @ptr, property.to_s).to_i
      end

      # Returns a string property.
      #
      # @raise [Exception::UnknownProperty]
      # @return [String]
      # @see #get_string
      # @see #get_property
      # @see #get_integer_property
      # @see #set_string_property
      def get_string_property(property)
        property = property.to_s
        raise Exception::UnknownProperty.new(property) unless valid_property?(property, :string)
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
        Weechat.__send__("#{self.class.type}_get_string", @ptr, property.to_s)
      end

      # Returns a hash representation of the associated infolist.
      #
      # @return [Hash{Symbol => Object}] All properties in the infolist
      def get_infolist
        Weechat::Infolist.parse(self.class.type, @ptr)
      end

      # Returns a property obtained by an infolist.
      #
      # @raise [Exception::UnknownProperty]
      # @return [String]
      # @see #get_property
      # @see #get_string_property
      # @see #get_integer_property
      def get_infolist_property(property)
        property = property.to_sym
        values = get_infolist.first
        raise Exception::UnknownProperty.new(property.to_s) unless values[property]
        values[property]
      end

      # Checks if a property can be set.
      #
      # @return [Boolean]
      # @see #valid_property?
      # @see #set_property
      def settable_property?(property)
        set_method = "#{self.class.type}_set"
        return false unless Weechat.respond_to?(set_method)

        property = property.to_s
        self.class.settable_properties.include?(property)
      end

      # Sets a property. Transformations, if appropriate, will be applied to the value
      # before setting it. This means that e.g. true and false will be turned into 1 and 0.
      #
      # @raise [Exception::UnsettableProperty]
      # @return [String, Integer] The value after if has been transformed
      # @see #set_string_property
      # @see #set
      def set_property(property, v, freeze = false)
        property = property.to_s
        raise Exception::UnsettableProperty.new(property) unless settable_property?(property)
        v = Utilities.apply_transformation(property, v, self.class.rtransformations)

        set(property, v)
        if freeze
          Property.properties.each do |prop|
            if prop[0..1] == [@ptr, property]
              prop[2].__freeze__
            end
          end
        end
      end

      # Sets a string property, not applying any transformations.
      #
      # @raise [Exception::UnsettableProperty]
      # @return [String] The value
      # @see #set_property
      # @see #set
      def set_string_property(property, v)
        property = property.to_s
        raise Exception::UnsettableProperty.new(property) unless settable_property?(property)
        set(property, v)
      end

      # Sets a property, not doing any checks or conversions whatsoever.
      #
      # @return [Object] The value
      # @see #set_property
      # @see #set_string_property
      def set(property, value)
        set_method = "#{self.class.type}_set"
        raise CannotSetProperties unless Weechat.respond_to?(set_method)
        Weechat.__send__(set_method, @ptr, property.to_s, value.to_s)
        value
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
          self.class.known_string_properties.include?(property) or valid_property?(property, :localvar)
        when :integer
          self.class.known_integer_properties.include?(property)
        when :localvar
          property =~ /^localvar_.+$/
        when :infolist
          get_infolist.first[property.to_sym]
        end
      end

      # method_missing returns buffer local variables.
      #
      # @return [String]
      def method_missing(m, *args)
        if args.empty? && valid_property?(m.to_s)
          get_property(m.to_s)
        else
          super
        end
      end

      def self.alias_methods(type)
        alias_method "#{type}_get_integer", :get_integer
        alias_method "#{type}_get_string", :get_string
      end
    end

    include ClassMethods
  end
end
