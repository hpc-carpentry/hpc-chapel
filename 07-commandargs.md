---
title: "Using command-line arguments"
teaching: 60
exercises: 30
---

:::::::::::::::::::::::::::::::::::::: questions
- "How do I use the same program for multiple use-cases?"
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives
- "Modifying code's constant parameters without re-compiling the code."
::::::::::::::::::::::::::::::::::::::::::::::::

From the last run of our code, we can see that 500 iterations is not enough to get to a _steady state_ (a
state where the difference in temperature does not vary too much, i.e. `delta`<`tolerance`). Now, if we want to
change the number of iterations we would need to modify `niter` in the code, and compile it again.  What if we
want to change the number of rows and columns in our grid to have more precision, or if we want to see the
evolution of the temperature at a different point (x,y)? The answer would be the same, modify the code and
compile it again!

No need to say that this would be very tedious and inefficient. A better scenario would be if we can pass the
desired configuration values to our binary when it is called at the command line. The Chapel mechanism for
this is to use **_config_** variables. When a variable is declared with the `config` keyword, in addition to
`var` or `const`, like this:

```chpl
config const niter = 500;    //number of iterations
```

it can be initialised with a specific value, when executing the code at the command line, using the syntax:

```bash
chpl base_solution.chpl
./base_solution --niter=3000
```

```output
The simulation will consider a matrix of 100 by 100 elements,
it will run up to 3000 iterations, or until the largest difference
in temperature between iterations is less than 0.0001.
You are interested in the evolution of the temperature at the 
position (1,100) of the matrix...

and here we go...
Temperature at iteration 0: 25.0
Temperature at iteration 20: 2.0859
Temperature at iteration 40: 1.42663
...
Temperature at iteration 2980: 0.793969
Temperature at iteration 3000: 0.793947

Final temperature at the desired position after 3000 iterations is: 0.793947
The greatest difference in temperatures between the last two iterations was: 0.000350086
```

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 4: Can you do it?

Make `outputFrequency`, `x`, `y`, `tolerance`, `rows` and `cols` configurable variables, and test the code
simulating different
configurations. What can you conclude about the performance of the code?

:::::::::::::::::::::::: solution

Let's prepend `config` to the following lines in our code:

```chpl
config const rows = 100;               // number of rows in the grid
config const cols = 100;               // number of columns in the grid
config const niter = 10_000;           // maximum number of iterations
config const x = 1;                    // row number for a printout
config const y = cols;                 // column number for a printout
config const tolerance: real = 0.0001; // smallest difference in temperature that would be accepted before stopping
config const outputFrequency: int = 20;   // the temperature will be printed every outputFrequency iterations
```

We can then recompile the code and try modifying some of these parameters from the command line. For example,
let's use a 650 x 650 grid and observe the evolution of the temperature at the position (200,300) for 10,000
iterations or until the difference of temperature between iterations is less than 0.002; also, let's print the
temperature every 1000 iterations.

```bash
chpl base_solution.chpl
./base_solution --rows=650 --cols=650 --x=200 --y=300 --tolerance=0.002 --outputFrequency=1000
```

```output
The simulation will consider a matrix of 650 by 650 elements, it will run up to 10000 iterations, or until
the largest difference in temperature between iterations is less than 0.002.  You are interested in the
evolution of the temperature at the position (200,300) of the matrix...

and here we go...
Temperature at iteration 0: 25.0
Temperature at iteration 1000: 25.0
Temperature at iteration 2000: 25.0
Temperature at iteration 3000: 25.0
Temperature at iteration 4000: 24.9998
Temperature at iteration 5000: 24.9984
Temperature at iteration 6000: 24.9935
Temperature at iteration 7000: 24.9819

Final temperature at the desired position after 7750 iterations is: 24.9671
The greatest difference in temperatures between the last two iterations was: 0.00199985
```

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: keypoints
- "Config variables accept values from the command line at runtime, without you having to recompile the code."
::::::::::::::::::::::::::::::::::::::::::::::::
