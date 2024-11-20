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
proc addOne(n) { // n is an input parameter
  return n + 1;
}
```

To call this procedure, you would use its name:

```chpl
writeln(addOne(10));
```

Procedures can be recursive, as demonstrated below. In this example the procedure takes an integer number as a
parameter and returns an integer number -- more on this below. If the input parameter is 1 or 0, `fibonacci`
will return the same input parameter. If the input parameter is 2 or larger, `fibonacci` will call itself
recursively.

```chpl
proc fibonacci(n: int): int { // input parameter type and procedure return type, respectively
  if n <= 1 then return n;
  return fibonacci(n-1) + fibonacci(n-2);
}
```
```chpl
writeln(fibonacci(10));
```

The input parameter type `n: int` is enforced at compilation time. For example, if you try to pass a real-type
number to the procedure with `fibonacci(10.2)`, you will get an error "error: unresolved call". Similarly, the
return variable type is also enforced at compilation time. For example, replacing `return n` with `return 1.0`
in line 2 will result in "error: cannot initialize return value of type 'int(64)'". While specifying these
types might be optional (see the call out below), we highly recommend doing so in your code, as it will add
additional checks for your program.

::::::::::::::::::::::::::::::::::::: callout

If not specified, the procedure return type is inferred from the return variable type. This might not be
possible with a recursive procedure as the return type is the procedure type, and it is not known to the
compiler, so in this case (and in the `fibonacci` example above) we need to specify the procedure return type
explicitly.

::::::::::::::::::::::::::::::::::::::::::::::::

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
```
```chpl
writeln(maxOf(1, -5, 123, 85, -17, 3));
writeln(maxOf(1.12, 0.85, 2.35));
```
```output
123
2.35
```

Procedures can have default parameter values. If a parameter with the default value (like `y` in the example
below) is not passed to the procedure, it takes the default value inside the procedure. If it is passed with
another value, then this new value is used inside the procedure.

In Chapel a procedure always returns a single value or a single data structure. In this example the procedure
returns a *tuple* (a structure) with two numbers inside, one integer and one real:

```chpl
proc returnTuple(x: int, y: real = 3.1415926): (int,real) {
  return (x,y);
}
```
```chpl
writeln(returnTuple(1));
writeln(returnTuple(x=2));
writeln(returnTuple(x=-10, y=10));
writeln(returnTuple(y=-1, x=3)); // the parameters can be named out of order
```

Chapel procedures have many other useful features, however, they are not essential for learning task and data
parallelism, so we refer the interested readers to the official Chapel documentation.

::::::::::::::::::::::::::::::::::::: keypoints
- "Functions in Chapel are called procedures."
- "Procedures can take a varying number of parameters."
- "Optionally, you can specify input parameter types and the return variable type."
- "Procedures can have default parameter values."
- "Procedures can be recursive. Recursive procedures require specifying the return variable type."
::::::::::::::::::::::::::::::::::::::::::::::::
