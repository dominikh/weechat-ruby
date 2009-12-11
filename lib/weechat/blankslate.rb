class Blankslate
  alias_method :__class__, :class
  instance_methods.each { |m| undef_method m unless m =~ /^__/ }
end
