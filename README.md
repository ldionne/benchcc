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

- Make it possible to add "configurations" for a single technique/benchmark,
  or to achieve an equivalent effect. I need this e.g. in the trampoline
  benchmark. For example, it should be possible to say something like:
  ```ruby
     benchmark :bm do
      config :fair do
        # Somehow specify what's special in this configuration
      end
      config :redundant do
        # We might want to do something like env[:redundancy] = 0.5
      end

      # Would we need a way to combine those configurations so we can
      # have redundant + fair without adding more code?
     end
  ```

- Allow specifying includes and switches to the compilers.

- (LOW PRIORITY) Make it possible to modify some attributes through
  the command line. For example, being able to modify the output/input
  sources on the command line could be handy.

- The way we set compilers in BenchmarkSuite and Benchmark is very brittle.
  It relies on us calling << to insert the first compiler.

- Provide a way to print the benchmarked code; this is super required for
  debugging.

- Provide a way to print the command line used for a given benchmark.

- Being able to specify stuff like --fair on the command line is useless.
  However, being able to set a version of a benchmark to be fair and another
  version to be unfair is required.

- When running the benchmarks, provide some info about what's going on. For
  example, what input size and what compiler we're currently using or
  something like that would be helpful.

- Consider allowing nested benchmark suites. Maybe this would not require much
  modifications to the code and this could be useful.

- `technique`s are really configs.
    ```ruby
        config :optional_name do
            requires do end
            env {key:value} do |e| # block is optional
            end
        end
    ```
