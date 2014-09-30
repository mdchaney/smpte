# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "smpte/version"

Gem::Specification.new do |s|
  s.name        = 'smpte'
  s.version     = SMPTE::VERSION
  s.licenses    = ['MIT', 'GPL-2']
  s.platform    = Gem::Platform::RUBY
  s.date        = '2014-09-28'
  s.summary     = "SMPTE Time code manipulation"
  s.description = <<-EOF
    The SMPTE gem provides a class for handling SMPTE time codes and
    includes functionality for parsing, comparing, adding, subtracting,
    converting and extracting frame counts.  This code was originally
    used by the author as part of an EDL parser.
  EOF
  s.author      = "Michael Chaney"
  s.email       = 'mdchaney@michaelchaney.com'
  s.homepage    = 'http://rubygems.org/gems/smpte'
  s.required_ruby_version = '>= 1.8.7'
  s.files       = Dir["{lib}/**/*.rb", "MIT-LICENSE", "GPLv2", "test"]
  s.require_path = 'lib'
  s.test_files  = Dir.glob('test/*.rb')
end
