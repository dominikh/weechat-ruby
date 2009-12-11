class NullOutput
  def write(*args)
  end
end

class Blankslate
  alias_method :__class__, :class

  old_stderr = $stderr.dup
  $stderr = NullOutput.new
  instance_methods.each { |m| undef_method m unless m =~ /^__/ }
  $stderr = old_stderr
end
