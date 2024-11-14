---
title: "Fire-and-forget tasks"
teaching: 60
exercises: 30
---

:::::::::::::::::::::::::::::::::::::: questions
- "How do we execute work in parallel?"
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives
- "Launching multiple threads to execute tasks in parallel."
- "Learn how to use `begin`, `cobegin`, and `coforall` to spawn new tasks."
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: callout

In the very first chapter where we showed how to run single-node Chapel codes. As a refresher, let's go over
this again. If you are running Chapel on your own computer, then you are all set, and you can simply compile
and run Chapel codes. If you are on a cluster, you will need to run Chapel codes inside interactive jobs. Here
so far we are covering only single-locale Chapel, so -- from the login node -- you can submit an interactive
job to the scheduler with a command like this one:

```sh
salloc --time=2:0:0 --ntasks=1 --cpus-per-task=3 --mem-per-cpu=1000
```

The details may vary depending on your cluster, e.g. different scheduler, requirement to specify an account or
reservation, etc, but the general idea remains the same: on a cluster you need to ask for resources before you
can run calculations. In this case we are asking for 2 hours maximum runtime, single MPI task (sufficient for
our parallelism in this chapter), 3 CPU cores inside that task, and 1000M maximum memory per core. The core
count means that we can run 3 threads in parallel, each on its own CPU core. Once your interactive job starts,
you can compile and run the Chapel codes below. Inside your Chapel code, when new threads start, they will be
able to utilize our 3 allocated CPU cores.

::::::::::::::::::::::::::::::::::::::::::::::::

A Chapel program always start as a single main thread. You can then start concurrent tasks with the `begin`
statement. A task spawned by the `begin` statement will run in a different thread while the main thread
continues its normal execution. Consider the following example:

```chpl
var x = 0;

writeln("This is the main thread starting first task");
begin
{
  var c = 0;
  while c < 10
  {
    c += 1;
    writeln('thread 1: ', x+c);
  }
}

writeln("This is the main thread starting second task");
begin
{
  var c = 0;
  while c < 10
  {
    c += 1;
    writeln('thread 2: ', x+c);
  }
}

writeln('this is main thread, I am done...');
```

```bash
chpl begin_example.chpl
./begin_example
```

```output
This is the main thread starting first task
This is the main thread starting second task
this is main thread, I am done...
thread 1: 1
thread 1: 2
thread 1: 3
thread 1: 4
thread 1: 5
thread 1: 6
thread 1: 7
thread 1: 8
thread 1: 9
thread 1: 10
thread 2: 1
thread 2: 2
thread 2: 3
thread 2: 4
thread 2: 5
thread 2: 6
thread 2: 7
thread 2: 8
thread 2: 9
thread 2: 10
```

As you can see the order of the output is not what we would expected, and actually it is completely
unpredictable. This is a well known effect of concurrent tasks accessing the same shared resource at the same
time (in this case the screen); the system decides in which order the tasks could write to the screen.






::::::::::::::::::::::::::::::::::::: challenge

## Challenge 1: what if `c` is defined globally?

What would happen if in the last code we *move* the definition of `c` into the main thread, but try to assign
it from threads 1 and 2? Select one answer from these:

1. The code will fail to compile.
1. The code will compile and run, but `c` will be updated by both threads at the same time (a *race
   condition*), so that its final value will vary from one run to another.
1. The code will compile and run, and the two threads will be taking turns updating `c`, so that its final
   value will always be the same.

:::::::::::::::::::::::: solution

We'll get an error at compilation ("cannot assign to const variable"), since then `c` would be defined within
the scope of the main thread, and we could modify its value only in the main thread. Any attempt to modify its
value inside threads 1 or 2 will produce a compilation error.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::







::::::::::::::::::::::::::::::::::::: challenge

## Challenge 2: what if we have a second, local definition of `x`?

What would happen if we try to insert a second definition `var x = 10;` inside the first `begin` statement?
Select one answer from these:

1. The code will fail to compile.
1. The code will compile and run, and the inside the first `begin` statement the value `x = 10` will be used,
   whereas inside the second `begin` statement the value `x = 0` will be used.
1. The new value `x = 10` will overwrite the global value `x = 0` in both threads 1 and 2.

:::::::::::::::::::::::: solution

The code will compile and run, and you will see the following output:

```output
This is the main thread starting first task
This is the main thread starting second task
this is main thread, I am done...
thread 1: 11
thread 1: 12
thread 1: 13
thread 1: 14
thread 1: 15
thread 1: 16
thread 1: 17
thread 1: 18
thread 1: 19
thread 1: 20
thread 2: 1
thread 2: 2
thread 2: 3
thread 2: 4
thread 2: 5
thread 2: 6
thread 2: 7
thread 2: 8
thread 2: 9
thread 2: 10
```

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: callout

All variables have a **_scope_** in which they can be used. The variables declared inside a concurrent task
are accessible only by that task. The variables declared in the main task can be read everywhere, but Chapel
won't allow other concurrent tasks to modify them.

::::::::::::::::::::::::::::::::::::::::::::::::







::::::::::::::::::::::::::::::::::::::: discussion

## Try this ...

Are the concurrent tasks, spawned by the last code, running truly in parallel?

The answer is: it depends on the number of cores available to your Chapel code. To verify this, let's modify the code
to get both threads 1 and 2 into an infinite loop:

```chpl
begin
{
  var c=0;
  while c > -1
  {
       c += 1;
      // the rest of the code in the thread
   }
}
```

Compile and run the code:

```sh
chpl begin_example.chpl
./begin_example
```

If you are running this on your own computer, you can run `top` or `htop` or `ps` commands in another terminal
to check Chapel's CPU usage. If you are running inside an interactive job on a cluster, you can open a
different terminal, log in to the cluster, and open a bash shell on the node that is running your job (if your
cluster setup allows this):

```sh
squeue -u $USER                   # check the jobID number
srun --jobid=<jobID> --pty bash   # put your jobID here
htop -u $USER -s PERCENT_CPU      # display CPU usage and other information
```

In the output of `htop` you will see a table with the list of your processes, and in the "CPU%" column you
will see the percentage consumed by each process. Find the Chapel process, and if it shows that your CPU usage
is close to 300%, you are using 3 CPU cores. What do you see?

Now exit `htop` by pressing *Q*. Also exit your interactive run by pressing *Ctrl-C*.

:::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: callout

To maximise performance, start as many tasks as cores are available.

::::::::::::::::::::::::::::::::::::::::::::::::

A slightly more structured way to start concurrent tasks in Chapel is by using the `cobegin`statement. Here
you can start a block of concurrent tasks, one for each statement inside the curly brackets. The main
difference between the `begin`and `cobegin` statements is that with the `cobegin`, all the spawned tasks are
synchronised at the end of the statement, i.e. the main thread won't continue its execution until all tasks
are done.

```chpl
var x=0;
writeln("This is the main thread, my value of x is ",x);

cobegin
{
  {
    var x=5;
    writeln("this is task 1, my value of x is ",x);
  }
  writeln("this is task 2, my value of x is ",x);
}

writeln("this message won't appear until all tasks are done...");
```

```bash
chpl cobegin_example.chpl
./cobegin_example
```

```output
This is the main thread, my value of x is 0
this is task 2, my value of x is 0
this is task 1, my value of x is 5
this message won't appear until all tasks are done...
```

As you may have conclude from the Discussion exercise above, the variables declared inside a task are
accessible only by the task, while those variables declared in the main task are accessible to all tasks.

The last, and most useful way to start concurrent/parallel tasks in Chapel, is the `coforall` loop. This is a
combination of the for-loop and the `cobegin`statements. The general syntax is:

```chpl
coforall index in iterand
{instructions}
```

This will start a new task, for each iteration. Each tasks will then perform all the instructions inside the
curly brackets. Each task will have a copy of the variable **_index_** with the corresponding value yielded by
the iterand.  This index allows us to _customise_ the set of instructions for each particular task.

```chpl
var x=1;
config var numoftasks=2;

writeln("This is the main task: x = ",x);

coforall taskid in 1..numoftasks
{
  var c=taskid+1;
  writeln("this is task ",taskid,": x + ",taskid," = ",x+taskid,". My value of c is: ",c);
}

writeln("this message won't appear until all tasks are done...");
```

```bash
chpl coforall_example.chpl
./coforall_example --numoftasks=5
```

```output
This is the main task: x = 1
this is task 5: x + 5 = 6. My value of c is: 6
this is task 2: x + 2 = 3. My value of c is: 3
this is task 4: x + 4 = 5. My value of c is: 5
this is task 3: x + 3 = 4. My value of c is: 4
this is task 1: x + 1 = 2. My value of c is: 2
this message won't appear until all tasks are done...
```

Notice how we are able to customise the instructions inside the coforall, to give different results depending
on the task that is executing them. Also, notice how, once again, the variables declared outside the coforall
can be read by all tasks, while the variables declared inside, are available only to the particular task.

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 3: Can you do it?

Would it be possible to print all the messages in the right order? Modify the code in the last example as
required.

Hint: you can use an array of strings declared in the main task, where all the concurrent tasks could write
their messages in the corresponding position. Then, at the end, have the main task printing all elements of
the array in order.

:::::::::::::::::::::::: solution

The following code is a possible solution:

```chpl
var x = 1;
config var numoftasks = 2;
var messages: [1..numoftasks] string;

writeln("This is the main task: x = ", x);

coforall taskid in 1..numoftasks {
  var c = taskid + 1;
  messages[taskid] = 'this is task ' + taskid:string +
    ': my value of c is ' + c:string + ' and x is ' + x:string;
}

for i in 1..numoftasks do writeln(messages[i]);
writeln("this message won't appear until all tasks are done...");
```

```bash
chpl exercise_coforall.chpl
./exercise_coforall --numoftasks=5
```

```output
This is the main task: x = 1
this is task 1: x + 1 = 2. My value of c is: 2
this is task 2: x + 2 = 3. My value of c is: 3
this is task 3: x + 3 = 4. My value of c is: 4
this is task 4: x + 4 = 5. My value of c is: 5
this is task 5: x + 5 = 6. My value of c is: 6
this message won't appear until all tasks are done...
```

Note that we need to convert integers to strings first (`taskid:string` converts `taskid` integer variable to
a string) before we can add them to other strings to form a message stored inside each `messages` element.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 4: Can you do it?

Consider the following code:

```chpl
use Random;
config const nelem = 100_000_000;
var x: [1..nelem] int;
fillRandom(x);	//fill array with random numbers
var mymax = 0;

// here put your code to find mymax

writeln("the maximum value in x is: ", mymax);
```

Write a parallel code to find the maximum value in the array x.

:::::::::::::::::::::::: solution

```chpl
config const numtasks = 12;
const n = nelem/numtasks;     // number of elements per thread
const r = nelem - n*numtasks; // these elements did not fit into the last thread

var d: [1..numtasks] int;  // local maxima for each thread

coforall taskid in 1..numtasks {
  var i, f: int;
  i  = (taskid-1)*n + 1;
  f = (taskid-1)*n + n;
  if taskid == numtasks then f += r; // add r elements to the last thread
  for j in i..f do
    if x[j] > d[taskid] then d[taskid] = x[j];
}
for i in 1..numtasks do
  if d[i] > mymax then mymax = d[i];
```

```bash
chpl --fast exercise_coforall_2.chpl
./exercise_coforall_2
```

```output
the maximum value in x is: 1
```

We use the `coforall` loop to spawn tasks that work concurrently in a fraction of the array. The trick here is to
determine, based on the _taskid_, the initial and final indices that the task will use. Each task obtains the
maximum in its fraction of the array, and finally, after the coforall is done, the main task obtains the
maximum of the array from the maximums of all tasks.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::: discussion

## Try this ...

Substitute the code to find _mymax_ in the last exercise with:

```chpl
mymax=max reduce x;
```

Time the execution of the original code and this new one. How do they compare?

:::::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::: callout

It is always a good idea to check whether there is _built-in_ functions or methods in the used language, that
can do what we want to do as efficiently (or better) than our house-made code. In this case, the _reduce_
statement reduces the given array to a single number using the given operation (in this case max), and it is
parallelized and optimised to have a very good performance.

::::::::::::::::::::::::::::::::::::::::::::::::


The code in these last Exercises somehow _synchronise_ the tasks to obtain the desired result. In addition,
Chapel has specific mechanisms task synchronisation, that could help us to achieve fine-grained
parallelization.

::::::::::::::::::::::::::::::::::::: keypoints
- "Use `begin` or `cobegin` or `coforall` to spawn new tasks."
- "You can run more than one task per core, as the number of cores on a node is limited."
::::::::::::::::::::::::::::::::::::::::::::::::
