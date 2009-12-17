class Blankslate
  instance_methods.each { |m| undef_method m unless m =~ /^__/ || m.to_s == 'object_id' }
end
