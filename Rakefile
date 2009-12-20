require 'rubygems'
require 'rake/gempackagetask'

VERSION = "0.0.2"

spec = Gem::Specification.new do |s|
  s.name              = "weechat"
  s.summary           = "An abstraction layer on top of the WeeChat API."
  s.description       = "An abstraction layer on top of the WeeChat API, allowing a cleaner and more intuitive way of writing Ruby scripts for WeeChat."
  s.version           = VERSION
  s.author            = "Dominik Honnef"
  s.email             = "dominikho@gmx.net"
  s.date              = Time.now.strftime "%Y-%m-%d"
  s.require_path      = "lib"
  s.homepage          = "http://dominikh.fork-bomb.de"
  s.rubyforge_project = ""

  s.has_rdoc = 'yard'

  # s.required_ruby_version = '>= 1.9.1'

  # s.add_dependency "keyword_arguments"

  # s.add_development_dependency "baretest"
  # s.add_development_dependency "mocha"

  s.files = FileList["bin/*", "lib/**/*.rb", "[A-Z]*", "examples/**/*"].to_a
  s.executables = [""]
end

Rake::GemPackageTask.new(spec)do |pkg|
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
  end
rescue LoadError
end

task :test do
  begin
    require "baretest"
  rescue LoadError => e
    puts "Could not run tests: #{e}"
  end

  BareTest.load_standard_test_files(
                                    :verbose => false,
                                    :setup_file => 'test/setup.rb',
                                    :chdir => File.absolute_path("#{__FILE__}/../")
                                    )

  BareTest.run(:format => "cli", :interactive => false)
end
