# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'benchcc/version'

Gem::Specification.new do |s|
  s.name          = "benchcc"
  s.version       = Benchcc::VERSION
  s.authors       = ["Louis Dionne"]
  s.email         = ["ldionne.2@gmail.com"]
  s.summary       = "A simple DSL for C++ compiler benchmarking automation"
  s.description   = s.summary
  s.homepage      = "http://github.com/ldionne/benchcc"
  s.license       = "MIT"
  s.files         = `git ls-files -z`.split("\x0")
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.5"
  s.add_development_dependency "rake", "~> 0"

  s.add_dependency "docile", "~> 1.1"
  s.add_dependency "gnuplot", "~> 2.6"
end