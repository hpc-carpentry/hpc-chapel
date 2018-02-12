---
title: "Conditional statements"
teaching: 60
exercises: 30
questions:
- "How do I add conditional logic to my code?"
objectives:
- "You can use the `==`, `>`, `>=`, etc. operators to make a comparison that returns true or false."
keypoints:
- "Conditional statements in Chapel are very similar to these in other languages."
---

Chapel, as most *high level programming languages*, has different staments to control the flow of the program or code.  The conditional statements are: the **_if statement_**, and the **_while statement_**.
These statements both rely on comparisons between values. 
Let's try a few comparisons to see how they work (`conditionals.chpl`):

```
writeln(1 == 2);
writeln(1 != 2);
writeln(1 > 2);
writeln(1 >= 2);
writeln(1 < 2);
writeln(1 <= 2);
```
{: .source}
```
chpl conditionals.chpl -o conditionals.o
./conditionals.o
```
{: .bash}
```
false
true
false
false
true
true
```
{: .output}

You can combine comparisons with the `&&` (AND) and `||` (OR) operators.
`&&` only returns `true` if both conditions are true, 
while `||` returns `true` if either condition is true.

```
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
{: .source}
```
chpl conditionals.chpl -o conditionals.o
./conditionals.o
```
{: .bash}
```
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
{: .output}

## Control flow

The general syntax of a while statement is: 

```
while condition do 
{instructions}
```

The code flows as follows: first, the condition is evaluated, and then, if it is satisfied, all the instructions within the curly brackets are executed one by one. This will be repeated over and over again until the condition does not hold anymore.

The main loop in our simulation can be programmed using a while statement like this

~~~
//this is the main loop of the simulation
var c = 0;
var curdif = mindif;
while (c < niter && curdif >= mindif) do
{
  c += 1;
  // actual simulation calculations will go here
}
~~~
{:.source}

Essentially, what we want is to repeat all the code inside the curly brackets until the number of iterations is gerater than or equal to `niter`, or the difference of temperature between iterations is less than `mindif`. (Note that in our case, as `curdif` was not initialized when declared -and thus Chapel assigned it the default real value 0.0-, we need to assign it a value greater than or equal to 0.001, or otherwise the condition of the while statemnt will never be satisfied. A good starting point is to simple say that `curdif` is equal to `mindif`).

To increase the number of iterations is not a problem, we just need to assign to `c` its current value plus 1, i.e. `c=c+1`, or in shorter form, using the compound assignment `+=` as in the code above, `c+=1`. To program the rest of the logic inside the curly brackets, on the other hand, we will need more elaborated instructions. 

Let's focus, first, on printing the temperature every 20 interations. To achieve this, we only need to check whether `c` is a multiple of 20, and in that case, to print the temperature at the desired position. This is the type of control that an **_if statement_** give us. The general syntax is: 

```
if condition then 
{instructions A} 
else 
{instructions B}
```

The set of instructions A is executed once if the condition is satisfied; the set of instructions B is executed otherwise (the else part of the if statement is optional). 

So, in our case this would do the trick:

~~~
if (c % 20 == 0)
{
  writeln('Temperature at iteration ', c, ': ', temp[x, y]);
}
~~~
{:.source}

Note that when only one instruction will be executed, there is no need to use the curly brackets. `%` is the modulo operator, it returns the remainder after the division (i.e. it returns zero when `c` is multiple of 20). 

Let's compile and execute our code to see what we get until now

```
const rows = 100;
const cols = 100;
const niter = 500;
const x = 50;                   // row number of the desired position
const y = 50;                   // column number of the desired position
const mindif = 0.0001;          // smallest difference in temperature that would be accepted before stopping

// this is our "plate"
var temp: [0..rows+1, 0..cols+1] real = 25;

writeln('This simulation will consider a matrix of ', rows, ' by ', cols, ' elements.');
writeln('Temperature at start is: ', temp[x, y]);

//this is the main loop of the simulation
var c = 0;
while (c < niter) do
{
  c += 1;
  if (c % 20 == 0)
  {
    writeln('Temperature at iteration ', c, ': ', temp[x, y]);
  }
}
```
{: .source}
~~~
chpl base_solution.chpl -o base_solution.o
./base_solution.o
~~~
{: .bash}
```
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
{:.output}

Of course the temperature is always 25.0 at any iteration other than the initial one, as we haven't done any computation yet.
