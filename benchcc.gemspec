# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'benchcc/version'

Gem::Specification.new do |s|
  s.name          = "benchcc"
  s.version       = Benchcc::VERSION
  s.authors       = ["Louis Dionne"]
  s.email         = ["ldionne.2@gmail.com"]
  s.homepage      = "https://github.com/ldionne/benchcc"
  s.license       = "Boost"
  s.summary       = "A collection of utilities to benchmark C++ metaprograms"
  s.description   = "Benchcc is a collection of utilities to make easier the task of benchmarking C++ metaprograms"

  s.files         = `git ls-files -z`.split("\x0")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ["lib"]

  s.add_dependency 'gnuplot', "~> 2.6"
  s.add_dependency 'rake', "~> 10.2"
  s.add_dependency 'ruby-progressbar', "~> 1.4"
  s.add_dependency 'tilt', '~> 2.0.1'
end