class String
  def remove_color(replacement='')
    Weechat.string_remove_color(self, replacement)
  end
  alias_method :remove_colors, :remove_color
  alias_method :strip_colors, :remove_color

  def remove_color!(replacement='')
    self.replace(remove_color(replacement))
  end
  alias_method :remove_colors!, :remove_color!
  alias_method :strip_colors!, :remove_color!
end
