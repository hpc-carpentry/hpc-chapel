---
title: "Conditional statements"
teaching: 60
exercises: 30
---

:::::::::::::::::::::::::::::::::::::: questions
- "How do I add conditional logic to my code?"
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives
- "You can use the `==`, `>`, `>=`, etc. operators to make a comparison that returns true or false."
::::::::::::::::::::::::::::::::::::::::::::::::

Chapel, as most *high level programming languages*, has different statements to control the flow of the
program or code. The conditional statements are: the **_if statement_**, and the **_while statement_**. These
statements both rely on comparisons between values. Let's try a few comparisons to see how they work
(`conditionals.chpl`):

```chpl
writeln(1 == 2);
writeln(1 != 2);
writeln(1 > 2);
writeln(1 >= 2);
writeln(1 < 2);
writeln(1 <= 2);
```

```bash
chpl conditionals.chpl
./conditionals
```

```output
false
true
false
false
true
true
```

You can combine comparisons with the `&&` (AND) and `||` (OR) operators. `&&` only returns `true` if both
conditions are true, while `||` returns `true` if either condition is true.

```chpl
writeln(1 == 2);
writeln(1 != 2);
writeln(1 > 2);
writeln(1 >= 2);
writeln(1 < 2);
writeln(1 <= 2);
writeln(true && true);
writeln(true && false);
writeln(true || false);
```

```bash
chpl conditionals.chpl
./conditionals
```

```output
false
true
false
false
true
true
true
false
true
```

## Control flow

The general syntax of a while statement is: 

```chpl
// single-statement form
while condition do
  instruction

// multi-statement form
while condition
{
  instructions
}
```

The code flows as follows: first, the condition is evaluated, and then, if it is satisfied, all the
instructions within the curly brackets or `do` are executed one by one. This will be repeated over and over again
until the condition does not hold anymore.

The main loop in our simulation can be programmed using a while statement like this

```chpl
//this is the main loop of the simulation
var c = 0;
delta = tolerance;
while (c < niter && delta >= tolerance)
{
  c += 1;
  // actual simulation calculations will go here
}
```

Essentially, what we want is to repeat all the code inside the curly brackets until the number of iterations
is greater than or equal to `niter`, or the difference of temperature between iterations is less than
`tolerance`. (Note that in our case, as `delta` was not initialised when declared -- and thus Chapel assigned it
the default real value 0.0 -- we need to assign it a value greater than or equal to 0.001, or otherwise the
condition of the while statement will never be satisfied. A good starting point is to simple say that `delta`
is equal to `tolerance`).

To count iterations we just need to keep adding 1 to the counter variable `c`.  We could do this with `c=c+1`,
or with the compound assignment, `+=`, as in the code above. To program the rest of the logic inside the curly
brackets, on the other hand, we will need more elaborated instructions.

Let's focus, first, on printing the temperature every `outputFrequency = 20` iterations. To achieve this, we
only need to check whether `c` is a multiple of `outputFrequency`, and in that case, to print the temperature
at the desired position. This is the type of control that an **_if statement_** give us. The general syntax
is:

```chpl
// single-statement form
if condition then
  instruction A
else
  instruction B

// multi-statement form
if condition
{instructions A}
else
{instructions B}
```

The set of instructions A is executed once if the condition is satisfied; the set of instructions B is
executed otherwise (the else part of the if statement is optional).

So, in our case this would do the trick:

```chpl
if (c % outputFrequency == 0)
{
  writeln('Temperature at iteration ', c, ': ', temp[x, y]);
}
```

Note that when only one instruction will be executed, there is no need to use the curly brackets. `%` is the
modulo operator, it returns the remainder after the division (i.e. it returns zero when `c` is multiple of
`outputFrequency`).

Let's compile and execute our code to see what we get until now

```chpl
const rows = 100;
const cols = 100;
const niter = 500;
const x = 50;                   // row number of the desired position
const y = 50;                   // column number of the desired position
const tolerance = 0.0001;       // smallest difference in temperature that
                                // would be accepted before stopping
const outputFrequency: int = 20;   // the temperature will be printed every outputFrequency iterations
var delta: real;                // greatest difference in temperature from one iteration to another 
var tmp: real;                  // for temporary results

// this is our "plate"
var temp: [0..rows+1, 0..cols+1] real = 25;

writeln('This simulation will consider a matrix of ', rows, ' by ', cols, ' elements.');
writeln('Temperature at start is: ', temp[x, y]);

//this is the main loop of the simulation
var c = 0;
delta = tolerance;
while (c < niter && delta >= tolerance)
{
  c += 1;
  if (c % outputFrequency == 0)
  {
    writeln('Temperature at iteration ', c, ': ', temp[x, y]);
  }
}
```

```bash
chpl base_solution.chpl
./base_solution
```

```output
This simulation will consider a matrix of 100 by 100 elements.
Temperature at start is: 25.0
Temperature at iteration 20: 25.0
Temperature at iteration 40: 25.0
Temperature at iteration 60: 25.0
Temperature at iteration 80: 25.0
Temperature at iteration 100: 25.0
Temperature at iteration 120: 25.0
Temperature at iteration 140: 25.0
Temperature at iteration 160: 25.0
Temperature at iteration 180: 25.0
Temperature at iteration 200: 25.0
Temperature at iteration 220: 25.0
Temperature at iteration 240: 25.0
Temperature at iteration 260: 25.0
Temperature at iteration 280: 25.0
Temperature at iteration 300: 25.0
Temperature at iteration 320: 25.0
Temperature at iteration 340: 25.0
Temperature at iteration 360: 25.0
Temperature at iteration 380: 25.0
Temperature at iteration 400: 25.0
Temperature at iteration 420: 25.0
Temperature at iteration 440: 25.0
Temperature at iteration 460: 25.0
Temperature at iteration 480: 25.0
Temperature at iteration 500: 25.0
```

Of course the temperature is always 25.0 at any iteration other than the initial one, as we haven't done any
computation yet.

::::::::::::::::::::::::::::::::::::: keypoints
- "Use `if <condition> {instructions A} else {instructions B}` syntax to execute one set of instructions
  if the condition is satisfied, and the other set of instructions if the condition is not satisfied."
- This syntax can be simplified to `if <condition> {instructions}` if we only want to execute the
  instructions within the curly brackets if the condition is satisfied.
- "Use `while <condition> {instructions}` to repeatedly execute the instructions within the curly brackets
  while the condition is satisfied. The instructions will be executed over and over again until the condition
  does not hold anymore."
::::::::::::::::::::::::::::::::::::::::::::::::
