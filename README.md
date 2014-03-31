# benchcc

> A DSL for C++ compiler benchmarking automation


## TODO
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

- Provide a way to print the benchmarked code; this is super required for
  debugging.

- Provide a way to print the command line used for a given benchmark.
