---
title: "Procedures for functional programming"
teaching: 15
exercises: 0
questions:
- "How do I write functions?"
objectives:
- "Be able to write our own procedures."
keypoints:
- "Functions in Chapel are called procedures."
- "Procedures can be recursive."
- "Procedures can take a variable number of parameters."
- "Procedures can have default parameter values."
---

Similar to other programming languages, Chapel lets you define your own
functions. These are called 'procedures' in Chapel and have an
easy-to-understand syntax:

~~~
proc addOne(n) { // n is an.bash parameter
  return n + 1;
}
writeln(addOne(10));
~~~
{: .source}

Procedures can be recursive:

~~~
proc fibonacci(n: int): int {
  if n <= 1 then return n;
  return fibonacci(n-1) + fibonacci(n-2);
}
writeln(fibonacci(10));
~~~
{: .source}

They can take a variable number of parameters:

~~~
proc maxOf(x ...?k) { // take a tuple of one type with k elements
  var maximum = x[1];
  for i in 2..k do maximum = if maximum < x[i] then x[i] else maximum;
  return maximum;
}
writeln(maxOf(1, -5, 123, 85, -17, 3));
~~~
{: .source}

Procedures can have default parameter values:

~~~
proc returnTuple(x: int, y: real = 3.1415926): (int,real) { // 
  return (x,y);
}
writeln(returnTuple(1));
writeln(returnTuple(x=2));
writeln(returnTuple(x=-10, y=10));
writeln(returnTuple(y=-1, x=3)); // the parameters can be named out of order
~~~
{: .source}

Chapel procedures have many other useful features, however, they are not
essential for learning task and data parallelism, so we refer the interested
readers to the official Chapel documentation.

