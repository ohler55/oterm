
require 'date'
require File.join(File.dirname(__FILE__), 'lib/oterm/version')

Gem::Specification.new do |s|
  s.name = "oterm"
  s.version = ::OTerm::VERSION
  s.authors = "Peter Ohler"
  s.date = Date.today.to_s
  s.email = "peter@ohler.com"
  s.homepage = "http://www.ohler.com/oterm"
  s.summary = "A operations terminal server."
  s.description = %{A remote terminal that can be used for interacting with an application and invoking operations remotely. Telnet and VT100 over a telnet connection are supported. }
  s.licenses = ['MIT', 'GPL-3.0']

  s.files = Dir["{lib,test}/**/*.{rb}"] + ['LICENSE', 'README.md']

  s.require_paths = ["lib"]

  s.has_rdoc = true
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options = ['--main', 'README.md']
  
  s.rubyforge_project = 'oterm'
end
