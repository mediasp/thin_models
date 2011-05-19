# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'lazy_data/version'

spec = Gem::Specification.new do |s|
  s.name   = "lazy-data"
  s.version = LazyData::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Matthew Willson']
  s.email = ["matthew@playlouder.com"]
  s.summary = "Help exposing data objects with array- or struct-like interfaces which are lazily evaluated at various levels of granularity"

  s.add_development_dependency('rake')
  s.add_development_dependency('test-spec')
  s.add_development_dependency('mocha')

  s.files = Dir.glob("{lib}/**/*") + ['README.txt']
end
