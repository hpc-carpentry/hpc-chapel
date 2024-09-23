---
title: "Procedures"
teaching: 15
exercises: 0
---

:::::::::::::::::::::::::::::::::::::: questions
- "How do I write functions?"
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives
- "Be able to write our own procedures."
::::::::::::::::::::::::::::::::::::::::::::::::

Similar to other programming languages, Chapel lets you define your own functions. These are called
'procedures' in Chapel and have an easy-to-understand syntax:

```chpl
proc addOne(n) { // n is an.bash parameter
  return n + 1;
}
writeln(addOne(10));
```

Procedures can be recursive:

```chpl
proc fibonacci(n: int): int {
  if n <= 1 then return n;
  return fibonacci(n-1) + fibonacci(n-2);
}
writeln(fibonacci(10));
```

Procedures can take a varying number of parameters. In this example the procedure `maxOf` takes two or more
parameters of the same type. This group of parameters is referred to as a *tuple* and is named `x` inside the
procedure. The number of elements `k` in this tuple is inferred from the number of parameters passed to the
procedure and is used to organize the calculations inside the procedure:

```chpl
proc maxOf(x ...?k) { // take a tuple of one type with k elements
  var maximum = x[1];
  for i in 2..k do maximum = if maximum < x[i] then x[i] else maximum;
  return maximum;
}
writeln(maxOf(1, -5, 123, 85, -17, 3));
writeln(maxOf(1.12, 0.85, 2.35));
```
```output
123
2.35
```

Procedures can have default parameter values:

```chpl
proc returnTuple(x: int, y: real = 3.1415926): (int,real) {
  return (x,y);
}
writeln(returnTuple(1));
writeln(returnTuple(x=2));
writeln(returnTuple(x=-10, y=10));
writeln(returnTuple(y=-1, x=3)); // the parameters can be named out of order
```

Chapel procedures have many other useful features, however, they are not essential for learning task and data
parallelism, so we refer the interested readers to the official Chapel documentation.

::::::::::::::::::::::::::::::::::::: keypoints
- "Functions in Chapel are called procedures."
- "Procedures can be recursive."
- "Procedures can take a varying number of parameters."
- "Procedures can have default parameter values."
::::::::::::::::::::::::::::::::::::::::::::::::
