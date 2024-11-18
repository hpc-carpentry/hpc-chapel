---
title: "Basic syntax and variables"
teaching: 15
exercises: 15
---

:::::::::::::::::::::::::::::::::::::: questions
- "How do I write basic Chapel code?"
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives
- "Perform basic maths in Chapel."
- "Understand Chapel's basic data types."
- "Understand how to read and fix errors."
- "Know how to define and use data stored as variables."
::::::::::::::::::::::::::::::::::::::::::::::::

Using basic maths in Chapel is fairly intuitive. Try compiling the following code to see
how the different mathematical operators work.

```chpl
writeln(4 + 5);
writeln(4 - 5);
writeln(4 * 5);
writeln(4 / 5);   // integer division
writeln(4.0 / 5.0); // floating-point division
writeln(4 ** 5);  // exponentiation
```

In this example, our code is called `operators.chpl`. You can compile it with the following commands:

```bash
chpl operators.chpl --fast
./operators
```

You should see output that looks something like the following:

```output
9
-1
20
0
0.8
1024
```

Code beginning with `//` is interpreted as a comment &mdash; it does not get run. Comments are very valuable
when writing code, because they allow us to write notes to ourselves about what each piece of code does. You
can also create block comments with `/*` and `*/`:

```chpl
/* This is a block comment.
It can span as many lines as you want!
(like this) */
```

## Variables

Granted, we probably want to do more than basic maths with Chapel. We will need to store the results of
complex operations using variables. Variables in programming are not the same as the mathematical concept. In
programming, a variable represents (or references) a location in the memory of the computer where we can store information or
data while executing a program. A variable has three elements:

1. a **_name_** or label, to identify the variable 
2. a **_type_**, that indicates the kind of data that we can store in it, and
3. a **_value_**, the actual information or data stored in the variable.

Variables in Chapel are declared with the `var` or `const` keywords. When a variable declared as `const` is
initialised, its value cannot be modified anymore during the execution of the program. What happens if we try to
modify a constant variable like `test` below?

```chpl
const test = 100;
test = 200;
writeln('The value of test is: ', test);
writeln(test / 4);
```
```bash
chpl variables.chpl
```
```error
variables.chpl:2: error: cannot assign to const variable
```

The compiler threw an error, and did not compile our program. This is a feature of compiled languages - if
there is something wrong, we will typically see an error at compile-time, instead of while running
it. Although we already kind of know why the error was caused (we tried to reassign the value of a `const`
variable, which by definition cannot be changed), let's walk through the error as an example of how to
troubleshoot our programs.

- `variables.chpl:2:` indicates that the error was caused on line 2 of our `variables.chpl` file.

- `error:` indicates that the issue was an error, and blocks compilation.  Sometimes the compiler will just
  give us warning or information, not necessarily errors. When we see something that is not an error, we
  should carefully read the output and consider if it necessitates changing our code.  Errors must be fixed,
  as they will block the code from compiling.

- `cannot assign to const variable` indicates that we were trying to reassign a `const` variable, which is
  explicitly not allowed in Chapel.

To fix this error, we can change `const` to `var` when declaring our `test` variable. `var` indicates a
variable that can be reassigned.

```chpl
var test = 100;
test = 200;
writeln('The value of test is: ', test);
writeln(test / 4);
```
```bash
chpl variables.chpl
```
```output
The value of test is: 200
50
```





In Chapel, to initialize a variable we must specify the type of the variable, or initialise it in place with
some value. The common variable types in Chapel are:

- integer `int` (positive or negative whole numbers)
- floating-point number `real` (decimal values)
- Boolean `bool`  (true or false)
- string `string` (any type of text)

These two variables below are initialized with the type. If no initial value is given, Chapel will initialise
a variable with a default value depending on the declared type, for example 0 for integers and 0.0 for real
variables.

```chpl
var counter: int;
var delta: real;
writeln("counter is ", counter, " and delta is ", delta);
```
```bash
chpl variables.chpl
./variables
```
```output
counter is 0 and delta is 0.0
```

If a variable is initialised with a value but without a type, Chapel will infer its type from the given
initial value:

```chpl
const test = 100;
writeln('The value of test is ', test, ' and its type is ', test.type:string);
```
```bash
chpl variables.chpl
./variables
```
```output
The value of test is 100 and its type is int(64)
```

When initialising a variable, we can also assign its type in addition to its value:

```chpl
const tolerance: real = 0.0001;
const outputFrequency: int = 20;
```

::::::::::::::::::::::::::::::::::::: callout

Note that these two notations below are different, but produce the same result in the end:

```chpl
var a: real = 10.0;   // we specify both the type and the value
var a = 10: real;     // we specify only the value (10 converted to real)
```

::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::: callout

In the following code (saved as `variables.chpl`) we have not initialised the variable `test` before trying to
use it in line 2:

```chpl
const test;  // declare 'test' variable
writeln('The value of test is: ', test);
```
```error
variables.chpl:1: error: 'test' is not initialized and has no type
variables.chpl:1: note: cannot find initialization point to split-init this variable
variables.chpl:2: note: 'test' is used here before it is initialized
```

::::::::::::::::::::::::::::::::::::::::::::::::

Now we know how to set, use, and change a variable, as well as the implications of using `var` and `const`. We
also know how to read and interpret errors.

Let's practice defining variables and use this as the starting point of our simulation code. The code will be
stored in the file `base_solution.chpl`. We will be solving the heat transfer problem introduced in the
previous section, starting with some initial temperature and computing a new temperature at each iteration. We
will then compute the greatest difference between the old and the new temperature and will check if it is
smaller than a preset `tolerance`. If no, we will continue iterating. If yes, we will stop iterations and will
print the final temperature. We will also stop iterations if we reach the maximum number of iterations
`niter`.

Our grid will be of size `rows` by `cols`, and every `outputFrequency`th iteration we will print temperature
at coordinates `x` and `y`.

The variable `delta` will store the greatest difference in temperature from one iteration to another. The
variable `tmp` will store some temporary results when computing the temperatures.

Let's define our variables:

```chpl
const rows = 100;               // number of rows in the grid
const cols = 100;               // number of columns in the grid
const niter = 500;              // maximum number of iterations
const x = 50;                   // row number for a printout
const y = 50;                   // column number for a printout
var delta: real;                // greatest difference in temperature from one iteration to another 
var tmp: real;                  // for temporary results
const tolerance: real = 0.0001; // smallest difference in temperature that would be accepted before stopping
const outputFrequency: int = 20;   // the temperature will be printed every outputFrequency iterations
```

::::::::::::::::::::::::::::::::::::: keypoints
- "A comment is preceded with `//` or surrounded by `/* and `*/`"
- "All variables in Chapel have a type, whether assigned explicitly by the user, or chosen by the Chapel
  compiler based on its value."
- "Reassigning a new value to a `const` variable will produce an error during compilation. If you want to assign a new value to a variable, declare that variable with the `var` keyword."
::::::::::::::::::::::::::::::::::::::::::::::::
