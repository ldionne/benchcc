# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'benchcc/version'

Gem::Specification.new do |s|
  s.name          = "benchcc"
  s.version       = Benchcc::VERSION
  s.authors       = ["Louis Dionne"]
  s.email         = ["ldionne.2@gmail.com"]
  s.homepage      = "https://github.com/ldionne/benchcc"
  s.license       = "MIT"
  s.summary       = "A simple DSL for C++ compiler benchmarking automation"
  s.description   = "Benchcc is a library of Rake tasks to make easier the task of benchmarking C++ compilation"

  s.files         = `git ls-files -z`.split("\x0")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ["lib"]

  s.add_dependency "gnuplot", "~> 2.6"
  s.add_dependency "rake", "~> 10.2"
  s.add_dependency "ruby-progressbar", "~> 1.4"
end