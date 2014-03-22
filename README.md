# benchcc

> A DSL for C++ compiler benchmarking automation


## TODO
- Consider allowing arbitrary attributes in e.g. BenchmarkSuite. Then, pass
  the suite to the created Benchmarks and they will fetch whatever they
  need from the enclosing BenchmarkSuite, if one is given. This way, we
  don't have to explicitly document and handle those attributes that we
  only forward to nested objects. To implement this, I should probably
  override method_missing.

- Allow specifying an input file as well as an input directory. If it's a
  directory, we consider the files with a certain pattern inside that
  directory. Otherwise, it is a file and we take it as-is.

- Make it possible to add "configurations" for a single technique, or to
  achieve an equivalent effect. I need this e.g. in the trampoline benchmark.

- Allow specifying includes and switches to the compilers.

- (LOW PRIORITY) Make it possible to modify some attributes through
  the command line. For example, being able to modify the output/input
  sources on the command line could be handy.