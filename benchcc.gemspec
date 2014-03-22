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
  s.description   = s.summary

  s.files         = `git ls-files -z`.split("\x0")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ["lib"]

  s.add_dependency "docile", "~> 1.1"
  s.add_dependency "gnuplot", "~> 2.6"
end