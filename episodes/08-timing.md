---
title: "Measuring code performance"
teaching: 60
exercises: 30
---

:::::::::::::::::::::::::::::::::::::: questions
- "How do I know how fast my code is?"
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives
- "Measuring code performance by instrumenting the code."
::::::::::::::::::::::::::::::::::::::::::::::::

The code generated after Exercise 4 is the basic implementation of our simulation. We will use it as a
benchmark, to see how much we can improve the performance when introducing the parallel programming features
of the language in the following lessons.

But first, we need a quantitative way to measure the performance of our code.  The easiest way to do it is to
see how long it takes to finish a simulation.  The UNIX command `time` could be used to this effect

```bash
time ./base_solution --rows=650 --cols=650 --x=200 --y=300 --tolerance=0.002 --outputFrequency=1000
```

```output
The simulation will consider a matrix of 650 by 650 elements,
it will run up to 10000 iterations, or until the largest difference
in temperature between iterations is less than 0.002.
You are interested in the evolution of the temperature at the 
position (200,300) of the matrix...

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

real	0m20.381s
user	0m20.328s
sys	0m0.053s
```

The real time is what interests us. Our code is taking around 20 seconds from the moment it is called at the
command line until it returns.

Some times, however, it could be useful to take the execution time of specific parts of the code. This can be
achieved by modifying the code to output the information that we need. This process is called
**_instrumentation of code_**.

An easy way to instrument our code with Chapel is by using the module `Time`.  **_Modules_** in Chapel are
libraries of useful functions and methods that can be used once the module is loaded. To load a module we use
the keyword `use` followed by the name of the module. Once the Time module is loaded we can create a variable
of the type `stopwatch`, and use the methods `start`,`stop`and `elapsed` to instrument our code.

```chpl
use Time;
var watch: stopwatch;
watch.start();

//this is the main loop of the simulation
delta=tolerance;
while (c<niter && delta>=tolerance) do
{
...
}

watch.stop();

//print final information
writeln('\nThe simulation took ',watch.elapsed(),' seconds');
writeln('Final temperature at the desired position after ',c,' iterations is: ',temp[x,y]);
writeln('The greatest difference in temperatures between the last two iterations was: ',delta,'\n');
```

```bash
chpl base_solution.chpl
./base_solution --rows=650 --cols=650 --x=200 --y=300 --tolerance=0.002 --outputFrequency=1000
```

```output
The simulation will consider a matrix of 650 by 650 elements,
it will run up to 10000 iterations, or until the largest difference
in temperature between iterations is less than 0.002.
You are interested in the evolution of the temperature at the 
position (200,300) of the matrix...

and here we go...
Temperature at iteration 0: 25.0
Temperature at iteration 1000: 25.0
Temperature at iteration 2000: 25.0
Temperature at iteration 3000: 25.0
Temperature at iteration 4000: 24.9998
Temperature at iteration 5000: 24.9984
Temperature at iteration 6000: 24.9935
Temperature at iteration 7000: 24.9819

The simulation took 20.1621 seconds
Final temperature at the desired position after 7750 iterations is: 24.9671
The greatest difference in temperatures between the last two iterations was: 0.00199985
```

::::::::::::::::::::::::::::::::::::: keypoints
- "To measure performance, instrument your Chapel code using a stopwatch from the `Time` module."
::::::::::::::::::::::::::::::::::::::::::::::::
