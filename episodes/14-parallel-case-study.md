---
title: "Task parallelism with Chapel"
teaching: 60
exercises: 30
---

:::::::::::::::::::::::::::::::::::::: questions
- "How do I write parallel code for a real use case?"
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives
- "First objective."
::::::::::::::::::::::::::::::::::::::::::::::::

Here is our plan to task-parallelize the heat transfer equation:

1. divide the entire grid of points into blocks and assign blocks to individual tasks,
1. each task should compute the new temperature of its assigned points,
1. perform a **_reduction_** over the whole grid, to update the greatest temperature difference between `Tnew`
   and `T`.

For the reduction of the grid we can simply use the `max reduce` statement, which is already
parallelized. Now, let's divide the grid into `rowtasks` x `coltasks` sub-grids, and assign each sub-grid to a
task using the `coforall` loop (we will have `rowtasks*coltasks` tasks in total).

```chpl
config const rowtasks = 2;
config const coltasks = 2;

// this is the main loop of the simulation
delta = tolerance;
while (c<niter && delta>=tolerance) do {
  c += 1;

  coforall taskid in 0..coltasks*rowtasks-1 do {
    for i in rowi..rowf do {
      for j in coli..colf do {
        temp[i,j] = (past_temp[i-1,j]+past_temp[i+1,j]+past_temp[i,j-1]+past_temp[i,j+1]) / 4;
      }
    }
  }

  delta = max reduce (temp-past_temp);
  past_temp = temp;

  if c%outputFrequency == 0 then writeln('Temperature at iteration ',c,': ',temp[x,y]);
}
```

Note that now the nested `for` loops run from `rowi` to `rowf` and from `coli` to `colf` which are,
respectively, the initial and final row and column of the sub-grid associated to the task `taskid`. To compute
these limits, based on `taskid`, we need to compute the number of rows and columns per task (`nr` and `nc`,
respectively) and account for possible non-zero remainders (`rr` and `rc`) that we should add to the last row
and column:

```chpl
config const rowtasks = 2;
config const coltasks = 2;

const nr = rows/rowtasks;
const rr = rows-nr*rowtasks;
const nc = cols/coltasks;
const rc = cols-nc*coltasks;

// this is the main loop of the simulation
delta = tolerance;
while (c<niter && delta>=tolerance) do {
  c+=1;

  coforall taskid in 0..coltasks*rowtasks-1 do {
    var rowi, coli, rowf, colf: int;
    var taskr, taskc: int;

    taskr = taskid/coltasks;
    taskc = taskid%coltasks;

    if taskr<rr then {
      rowi=(taskr*nr)+1+taskr;
      rowf=(taskr*nr)+nr+taskr+1;
    }
    else {
      rowi = (taskr*nr)+1+rr;
      rowf = (taskr*nr)+nr+rr;
    }

    if taskc<rc then {
      coli = (taskc*nc)+1+taskc;
      colf = (taskc*nc)+nc+taskc+1;
    }
    else {
      coli = (taskc*nc)+1+rc;
      colf = (taskc*nc)+nc+rc;
    }

    for i in rowi..rowf do {
      for j in coli..colf do {
      ...
}
```

As you can see, to divide a data set (the array `temp` in this case) between concurrent tasks, could be
cumbersome. Chapel provides high-level abstractions for data parallelism that take care of all the data
distribution for us. We will study data parallelism in the following lessons, but for now, let's compare the
benchmark solution with our `coforall` parallelization to see how the performance improved.

```bash
chpl --fast parallel_solution_1.chpl -o parallel1
./parallel1 --rows=650 --cols=650 --x=200 --y=300 --niter=10000 --tolerance=0.002 --n=1000
```

```output
The simulation will consider a matrix of 650 by 650 elements,
it will run up to 10000 iterations, or until the largest difference
in temperature between iterations is less than 0.002.
You are interested in the evolution of the temperature at the position (200,300) of the matrix...

and here we go...
Temperature at iteration 0: 25.0
Temperature at iteration 1000: 25.0
Temperature at iteration 2000: 25.0
Temperature at iteration 3000: 25.0
Temperature at iteration 4000: 24.9998
Temperature at iteration 5000: 24.9984
Temperature at iteration 6000: 24.9935
Temperature at iteration 7000: 24.9819

The simulation took 17.0193 seconds
Final temperature at the desired position after 7750 iterations is: 24.9671
The greatest difference in temperatures between the last two iterations was: 0.00199985
```

This parallel solution, using 4 parallel tasks, took around 17 seconds to finish. Compared with the ~20
seconds needed by the benchmark solution, seems not very impressive. To understand the reason, let's analyse
the code's flow.  When the program starts, the main thread does all the declarations and initialisations, and
then, it enters the main loop of the simulation (the **_while loop_**). Inside this loop, the parallel tasks
are launched for the first time. When these tasks finish their computations, the main task resumes its
execution, it updates `delta`, and everything is repeated again. So, in essence, parallel tasks are launched
and resumed 7750 times, which introduces a significant amount of overhead (the time the system needs to
effectively start and destroy threads in the specific hardware, at each iteration of the while loop).

Clearly, a better approach would be to launch the parallel tasks just once, and have them executing all the
simulations, before resuming the main task to print the final results.

```chpl
config const rowtasks = 2;
config const coltasks = 2;

const nr = rows/rowtasks;
const rr = rows-nr*rowtasks;
const nc = cols/coltasks;
const rc = cols-nc*coltasks;

// this is the main loop of the simulation
delta = tolerance;
coforall taskid in 0..coltasks*rowtasks-1 do {
  var rowi, coli, rowf, colf: int;
  var taskr, taskc: int;
  var c = 0;

  taskr = taskid/coltasks;
  taskc = taskid%coltasks;

  if taskr<rr then {
    rowi = (taskr*nr)+1+taskr;
    rowf = (taskr*nr)+nr+taskr+1;
  }
  else {
    rowi = (taskr*nr)+1+rr;
    rowf = (taskr*nr)+nr+rr;
  }

  if taskc<rc then {
    coli = (taskc*nc)+1+taskc;
    colf = (taskc*nc)+nc+taskc+1;
  }
  else {
    coli = (taskc*nc)+1+rc;
    colf = (taskc*nc)+nc+rc;
  }

  while (c<niter && delta>=tolerance) do {
    c = c+1;

    for i in rowi..rowf do {
      for j in coli..colf do {
        temp[i,j] = (past_temp[i-1,j]+past_temp[i+1,j]+past_temp[i,j-1]+past_temp[i,j+1])/4;
      }
    }

    //update delta
    //update past_temp
    //print temperature in desired position
  }
}
```

The problem with this approach is that now we have to explicitly synchronise the tasks. Before, `delta` and
`past_temp` were updated only by the main task at each iteration; similarly, only the main task was printing
results. Now, all these operations must be carried inside the coforall loop, which imposes the need of
synchronisation between tasks.

The synchronisation must happen at two points:

1. We need to be sure that all tasks have finished with the computations of their part of the grid `temp`,
   before updating `delta` and `past_temp` safely.
2. We need to be sure that all tasks use the updated value of `delta` to evaluate the condition of the while
   loop for the next iteration.

To update `delta` we could have each task computing the greatest difference in temperature in its associated
sub-grid, and then, after the synchronisation, have only one task reducing all the sub-grids' maximums.

```chpl
var delta: atomic real;
var myd: [0..coltasks*rowtasks-1] real;
...
//this is the main loop of the simulation
delta.write(tolerance);
coforall taskid in 0..coltasks*rowtasks-1 do
{
  var myd2: real;
  ...

  while (c<niter && delta>=tolerance) do {
    c = c+1;
    ...

    for i in rowi..rowf do {
      for j in coli..colf do {
        temp[i,j] = (past_temp[i-1,j]+past_temp[i+1,j]+past_temp[i,j-1]+past_temp[i,j+1])/4;
        myd2 = max(abs(temp[i,j]-past_temp[i,j]),myd2);
      }
    }
    myd[taskid] = myd2

    // here comes the synchronisation of tasks

    past_temp[rowi..rowf,coli..colf] = temp[rowi..rowf,coli..colf];
    if taskid==0 then {
      delta.write(max reduce myd);
      if c%outputFrequency==0 then writeln('Temperature at iteration ',c,': ',temp[x,y]);
    }

    // here comes the synchronisation of tasks again
  }
}
```

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 4: Can you do it?

Use `sync` or `atomic` variables to implement the synchronisation required in the code above.

:::::::::::::::::::::::: solution

One possible solution is to use an atomic variable as a _lock_ that opens (using the `waitFor` method) when
all the tasks complete the required instructions

```chpl
var lock: atomic int;
lock.write(0);
...
//this is the main loop of the simulation
delta.write(tolerance);
coforall taskid in 0..coltasks*rowtasks-1 do
{
   ...
   while (c<niter && delta>=tolerance) do
   {
      ...
      myd[taskid]=myd2

      //here comes the synchronisation of tasks
      lock.add(1);
      lock.waitFor(coltasks*rowtasks);

      past_temp[rowi..rowf,coli..colf]=temp[rowi..rowf,coli..colf];
      ...

      //here comes the synchronisation of tasks again
      lock.sub(1);
      lock.waitFor(0);
   }
}
```

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

Using the solution in the Exercise 4, we can now compare the performance with the benchmark solution

```bash
chpl --fast parallel_solution_2.chpl -o parallel2
./parallel2 --rows=650 --cols=650 --x=200 --y=300 --niter=10000 --tolerance=0.002 --n=1000
```

```output
The simulation will consider a matrix of 650 by 650 elements,
it will run up to 10000 iterations, or until the largest difference
in temperature between iterations is less than 0.002.
You are interested in the evolution of the temperature at the position (200,300) of the matrix...

and here we go...
Temperature at iteration 0: 25.0
Temperature at iteration 1000: 25.0
Temperature at iteration 2000: 25.0
Temperature at iteration 3000: 25.0
Temperature at iteration 4000: 24.9998
Temperature at iteration 5000: 24.9984
Temperature at iteration 6000: 24.9935
Temperature at iteration 7000: 24.9819

The simulation took 4.2733 seconds
Final temperature at the desired position after 7750 iterations is: 24.9671
The greatest difference in temperatures between the last two iterations was: 0.00199985
```

to see that we now have a code that performs 5x faster.

We finish this section by providing another, elegant version of the 2D heat transfer solver (without time
stepping) using data parallelism on a single locale:

```chpl
const n = 100, stride = 20;
var T: [0..n+1, 0..n+1] real;
var Tnew: [1..n,1..n] real;
var x, y: real;
for (i,j) in {1..n,1..n} { // serial iteration
  x = ((i:real)-0.5)/n;
  y = ((j:real)-0.5)/n;
  T[i,j] = exp(-((x-0.5)**2 + (y-0.5)**2)/0.01); // narrow Gaussian peak
}
coforall (i,j) in {1..n,1..n} by (stride,stride) { // 5x5 decomposition into 20x20 blocks => 25 tasks
  for k in i..i+stride-1 { // serial loop inside each block
    for l in j..j+stride-1 do {
      Tnew[k,l] = (T[k-1,l] + T[k+1,l] + T[k,l-1] + T[k,l+1]) / 4;
    }
  }
}
```

We will study data parallelism in more detail in the next section.

::::::::::::::::::::::::::::::::::::: keypoints
- "To parallelize the diffusion solver with tasks, you divide the 2D domain into blocks and assign each block
  to a task."
- "To get the maximum performance, you need to launch the parallel tasks only once, and run the temporal loop
  of the simulation with the same set of tasks, resuming the main task only to print the final results."
- "Parallelizing with tasks is more laborious than parallelizing with data (covered in the next section)."
::::::::::::::::::::::::::::::::::::::::::::::::
