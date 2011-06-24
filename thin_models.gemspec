# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'thin_models/version'

spec = Gem::Specification.new do |s|
  s.name   = "thin_models"
  s.version = ThinModels::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Matthew Willson']
  s.email = ["matthew@playlouder.com"]
  s.summary = "Some convenience classes for 'thin models' -- pure domain model data objects which are devoid of persistence and other infrastructural concerns"

  s.add_development_dependency('rake')
  s.add_development_dependency('test-spec')
  s.add_development_dependency('mocha')
  s.add_development_dependency('autotest')

  s.files = Dir.glob("{lib}/**/*") + ['README.txt']
end
