# benchcc

> A simple DSL for C++ compiler benchmarking automation

## TODO
- Add some kind of benchmark suite that can handle several benchmarks and
  run them. It must be possible to skip failed benchmarks without stopping.
- Add benchmarking of the memory usage when compiling.
- Make it possible to customize the output of benchmarks. Maybe we only want
  to do this at the suite level?
- It would be useful to run benchmarks automatically with different compilers.
  Add support for this unless it's very complicated and better handled at the
  Rakefile/command line level