( (0..1000).map { |n| [1, n] } +
  (0..400).map { |n| [n, 10] }
).map { |breadth, depth|
  { breadth: breadth, depth: depth }
}