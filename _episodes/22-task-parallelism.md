---
title: "Task Parallelism with Chapel"
teaching: 60
exercises: 30
questions:
- "Key question"
objectives:
- "First objective."
keypoints:
- "First key point."
---

The basic concept of parallel computing is simple to understand: we divide our job in tasks that can be executed at the same time, so that we finish the job in a fraction of the time that it would have taken if the tasks are executed one by one.  Implementing parallel computations, however, is not always easy, nor possible...

A number of misconceptions arises when implementing parallel computations, and we need to address them before looking into how task parallelism works in Chapel. To this effect, let's consider the following analogy:

Suppose that we want to paint the four walls in a room. This is our problem. We can divide our problem in 4 different tasks: paint each of the walls. In principle, our 4 tasks are independent from each other in the sense that we don't need to finish one to start one another. We say that we have 4 **_concurrent tasks_**; the tasks can be executed within the same time frame. However, this does not mean that the tasks can be executed simultaneously or in parallel. It all depends on the amount of resources that we have for the tasks. If there is only one painter, this guy could work for a while in one wall, then start painting another one, then work for a little bit in the third one, and so on and so for. **_The tasks are being executed concurrently but not in parallel_**. If we have 2 painters for the job, then more parallelism can be introduced. 4 painters could executed the tasks **_truly in parallel_**. 

> ## Key idea
Think of the CPU cores as the painters or workers that will execute your concurrent tasks
{:.callout}

Now imagine that all workers have to obtain their paint form a central dispenser located at the middle of the room. If each worker is using a different colour, then they can work **_asynchronously_**, however, if they use the same colour, and two of them run out of paint at the same time, then they have to **_synchronize_** to use the dispenser, one should wait while the other is being serviced.  

> ## Key idea
Think of the shared memory in your computer as the central dispenser for all your workers
{:.callout}

Finally, imagine that we have 4 paint dispensers, one for each worker. In this scenario, each worker can complete its task totally on its own. They don't even have to be in the same room, they could be painting walls of different rooms in the house, on different houses in the city, and different cities in the country. We need, however, a communication system in place. Suppose that worker A, for some reason, needs a colour that is only available in the dispenser of worker B, they should then synchronize: worker A should request the paint to worker B and this last one should response by sending the required colour. 

> ## Key idea
Think of the memory distributed on each node of a cluster as the different dispensers for your workers
{:.callout}

A **_fine-grained_** parallel code needs lots of communication/synchronization between tasks, in contrast with a **_course-grained_** one. An **_embarrassing parallel_** problem is one where all tasks can be executed completely independent from each other (no communications required). 

## Parallel programming in Chapel

Chapel provides high-level abstractions for parallel programming no matter the grain size of your tasks, whether they run in a shared memory or a distributed memory environment, or whether they are executed concurrently or truly in parallel. As a programmer you can focus in the algorithm: how to divide the problem into tasks that make sense in the context of the problem, and be sure that the high-level implementation will run on any hardware configuration. Then you could consider the specificities of the particular system you are going to use (whether is shared or distributed, the number of cores, etc.) and tune your code/algorithm to obtain a better performance. 

> ## Key idea
To this effect, **_concurrency_** (the creation and execution of multiple tasks), and **_locality_** (in which set of resources these tasks are executed) are orthogonal concepts in Chapel. 
{:.callout}

In summary, we can have a set of several tasks; these tasks could be running:
```
a. concurrently by the same processor in a single compute node,
b. in parallel by several processors in a single compute node,
c. in parallel by several processors distributed in different compute nodes, or
d. serially (one by one) by several processors distributed in different compute nodes. 
```
Similarly, each of these tasks could be using variables located in: 
```
a. the local memory on the compute node where it is running, or 
b. on distributed memory located in other compute nodes. 
```
 And again, Chapel could take care of all the stuff required to run our algorithm in most of the scenarios, but we can always add more specific detail to gain performance when targeting a particular scenario. 
 
## Fire-and-forget tasks

 A Chapel program always start as a single main thread. You can then start concurrent tasks with the `begin` statement. A task spawned by the `begin` statement will run in a different thread while the main thread continues its normal execution. Consider the following example:
 
 ~~~
 var x=0;

writeln("This is the main thread starting first task");
begin
{
  var c=0;
  while c<100
  {
    c+=1;
    writeln('thread 1: ',x+c);
  }
}

writeln("This is the main thread starting second task");
begin
{
  var c=0;
  while c<100
  {
    c+=1;
    writeln('thread 2: ',x+c);
  }
}

writeln('this is main thread, I am done...');
~~~
{:.source}
 
 ~~~
 >> chpl begin_example.chpl -o begin_example
 >> ./begin_example
 ~~~
 {:.input}
 
 ~~~
This is the main thread starting first task
This is the main thread starting second task
this is main thread, I am done...
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
thread 2: 11
thread 2: 12
thread 2: 13
thread 1: 1
thread 2: 14
thread 1: 2
thread 2: 15
...
thread 2: 99
thread 1: 97
thread 2: 100
thread 1: 98
thread 1: 99
thread 1: 100
~~~
{:.output}

As you can see the order of the output is not what we would expected, and actually it is completely unpredictable. This is a well known effect of concurrent tasks accessing the same shared resource at the same time (in this case the screen); the system decides in which order the tasks could write to the screen. 

> ## Discussion
> What would happen if in the last code we declare `c` in the main thread? 
> What would happen if we try to modify the value of `x`inside a begin statement?
> Discuss your observations.
>> ## Key idea
>> All variables have a **_scope_** in which they can be used. The variables declared inside a concurrent tasks are accessible only by the task. The variables declared in the main task can be read everywhere, but Chapel won't allow two concurrent tasks to try to modify them. 
> {:.solution}
{:.discussion}

> ## Try this...
> Are the concurrent tasks, spawned by the last code, running truly in parallel?
>
> The answer is: it depends on the number of cores available to your job. To verify this, let's modify the code to get the tasks into an infinite loop
>  ~~~
>  begin
>  {
>    var c=0;
>    while c>-1
>    {
>         c+=1;
>        //writeln('thread 1: ',x+c);
>     }
>  }
> ~~~
> {:.source}
>
> Now submit your job asking for different amount of resources, and use system tools such as `top`or `ps` to monitor the execution of the code.
>> ## Key idea
>> To maximize performance, start as many tasks as cores are avaialble
>{:.solution}
{:.challenge}

A slightly more structured way to start concurrent tasks in Chapel is by using the `cobegin`statement. Here you can start a block of concurrent tasks, one for each statement inside the curly brackets. The main difference between the `begin`and `cobegin` statements is that with the `cobegin`, all the spawned tasks are synchronized at the end of the statement, i.e. the main thread won't continue its execution until all tasks are done. 

~~~
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
~~~
{:.source}

~~~
 >> chpl cobegin_example.chpl -o cobegin_example
 >> ./cobegin_example
 ~~~
 {:.input}
 
 ~~~
This is the main thread, my value of x is 0
this is task 2, my value of x is 0
this is task 1, my value of x is 5
this message won't appear until all tasks are done...
 ~~~
 {:.output}

As you may have conclude from the Discussion exercise above, the variables declared inside a task are accessible only by the task, while those variables declared in the main task are accessible to all tasks. 

The last, and most useful way to start concurrent/parallel tasks in Chapel, is the `coforall` loop. This is a combination of the for-loop and the `cobegin`statements. The general syntax is:

```
coforall index in iterand 
{instructions}
```
This will start a new task, for each iteration. Each tasks will then perform all the instructions inside the curly brackets. Each task will have a copy of the variable **_index_** with the corresponding value yielded by the iterand. This index allows us to _customize_ the set of instructions for each particular task. 

~~~
var x=1;
config var numoftasks=2;

writeln("This is the main task: x = ",x);

coforall taskid in 1..numoftasks do 
{
  var c=taskid+1;
  writeln("this is task ",taskid,": x + ",taskid," = ",x+taskid,". My value of c is: ",c);
}

writeln("this message won't appear until all tasks are done...");
~~~
{:.source}

~~~
 >> chpl coforall_example.chpl -o coforall_example
 >> ./coforall_example --numoftasks=5
 ~~~
 {:.input}
 
 ~~~
This is the main task: x = 1
this is task 5: x + 5 = 6. My value of c is: 6
this is task 2: x + 2 = 3. My value of c is: 3
this is task 4: x + 4 = 5. My value of c is: 5
this is task 3: x + 3 = 4. My value of c is: 4
this is task 1: x + 1 = 2. My value of c is: 2
this message won't appear until all tasks are done...
 ~~~
 {:.output}
 
Notice how we are able to customize the instructions inside the coforall, to give different results depending on the task that is executing them. Also, notice how, once again, the variables declared outside the coforall can be read by all tasks, while the variables declared inside, are available only to the particular task. 

> ## Exercise 1
> Would it be possible to print all the messages in the right order? Modify the code in the last example as required.
>
> Hint: you can use an array of strings declared in the main task, where all the concurrent tasks could write their messages in the corresponding position. Then, at the end, have the main task printing all elements of the array in order.
>> ## Solution
>> The following code is a possible solution:
>> ~~~
>> var x=1;
>> config var numoftasks=2;
>> var messages: [1..numoftasks] string;
>>
>> writeln("This is the main task: x = ",x);
>>
>> coforall taskid in 1..numoftasks do
>> {
>>    var c=taskid+1;
>>    var s="this is task "+taskid+": x + "+taskid+" = "+(x+taskid)+". My value of c is: "+c;
>>    messages[taskid]=s;
>> }
>>
>> for i in 1..numoftasks do writeln(messages[i]);
>> writeln("this message won't appear until all tasks are done...");
>> ~~~
>> {:.source}
>>
>> ~~~
>> chpl exercise_coforall.chpl -o exercise_coforall
>> ./exercise_coforall --numoftasks=5
>> ~~~
>> {:.input}
>>
>> ~~~
This is the main task: x = 1
this is task 1: x + 1 = 2. My value of c is: 2
this is task 2: x + 2 = 3. My value of c is: 3
this is task 3: x + 3 = 4. My value of c is: 4
this is task 4: x + 4 = 5. My value of c is: 5
this is task 5: x + 5 = 6. My value of c is: 6
this message won't appear until all tasks are done...
>> ~~~
>> {:.output}
>>
>> Note that `+` is a **_polymorphic_** operand in Chapel. In this case it concatenates `strings` with `integers` (which are transformed to strings). 
> {:.solution}
{:.challenge}

> ## Exercise 2
> Consider the following code:
> ~~~
> use Random;
> config const nelem=5000000000;
> var x: [1..n] int;
> fillRandom(x);	//fill array with random numbers
> var mymax=0;
>
> // here put your code to find mymax
>
> writeln("the maximum value in x is: ",mymax);
> ~~~
> {:.source}
> Write a parallel code to find the maximum value in the array x
>> ## Solution
>> ~~~
>> config const numoftasks=12;
>> const n=nelem/numoftasks;
>> const r=nelem-n*numoftasks;
>>
>> var d: [0..numoftasks-1] real;
>>
>> coforall taskid in 0..numoftasks-1 do
>> {
>>   var i: int;
>>   var f: int;
>>   if taskid<r then
>>   {
>>      i=taskid*n+1+taskid;
>>      f=taskid*n+n+taskid+1;
>>   }
>>  else
>>  {
>>       i=taskid*n+1+r;
>>       f=taskid*n+n+r;
>>   }
>>   for c in i..f do
>>   {
>>       if x[c]>d[taskid] then d[taskid]=x[c];
>>   }
>> }
>> for i in 0..numoftasks-1 do
>> {
>>   if d[i]>mymax then mymax=d[i];
>> }
>> ~~~
>> {:.source}
>>
>> ~~~
>> >> chpl --fast exercise_coforall_2.chpl -o exercise_coforall_2
>> >> ./exercise_coforall_2 
>> ~~~
>> {:.input}
>>
>> ~~~
>> the maximum value in x is: 1.0
>> ~~~
>> {:.output}
>>
>> We use the coforall to spawn tasks that work concurrently in a fraction of the array. The trick here is to determine, based on the _taskid_, the initial and final indices that the task will use. Each task obtains the maximum in its fraction of the array, and finally, after the coforall is done, the main task obtains the maximum of the array from the maximums of all tasks.  
> {:.solution}
{:.challenge}

> ## Discussion
> Run the code of last Exercise using different number of tasks, and different sizes of the array _x_ to see how the execution time changes. For example:
> ~~~
> >> time ./exercise_coforall_2 --nelem=3000 --numoftasks=4
> ~~~
> {:.input}
>
> Discuss your observations. Is there a limit on how fast the code could run?
{:.discussion}

> ## Try this...
> Substitute the code to find _mymax_ in the last exercise with:
> ~~~
> mymax=max reduce x;
> ~~~
> {:.source}
> Time the execution of the original code and this new one. How do they compare?
>
>> ## Key idea
>> It is always a good idea to check whether there is _built-in_ functions or methods in the used language, that can do what we want to do as efficiently (or better) than our house-made code. In this case, the _reduce_ statement reduces the given array to a single number using the given operation (in this case max), and it is parallelized and optimized to have a very good performance. 
>{:.solution}
{:.challenge}


The code in these last Exercises somehow _synchronize_ the tasks to obtain the desired result. In addition, Chapel has specific mechanisms task synchronization, that could help us to achieve fine-grained parallelization. 

## Synchronization of tasks

The keyword `sync` provides all sorts of mechanisms to synchronize tasks in Chapel. 

We can simply use `sync` to force the _parent_ task to stop and wait until its _spawned-child-task_ ends.

~~~
var x=0;
writeln("This is the main thread starting a synchronous task");

sync
{
  begin
  {
    var c=0;
    while c<10
    {
      c+=1;
      writeln('thread 1: ',x+c);
    }
  }
}
writeln("The first task is done...");

writeln("This is the main thread starting an asynchronous task");
begin
{
  var c=0;
  while c<10
  {
    c+=1;
    writeln('thread 2: ',x+c);
  }
}

writeln('this is main thread, I am done...');
~~~
{:.source}

~~~
>> chpl sync_example_1.chpl -o sync_example_1
>> ./sync_example_1 
~~~
{:.input}

~~~
This is the main thread starting a synchronous task
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
The first task is done...
This is the main thread starting an asynchronous task
this is main thread, I am done...
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
~~~
{:.output}

> ## Discussion
> What would happen if we write instead 
> ~~~
begin
{
  sync
  {
    var c=0;
    while c<10
    {
      c+=1;
      writeln('thread 1: ',x+c);
    }
  }
}
writeln("The first task is done...");
> ~~~
> {:.source}
> Discuss your observations. 
{:.discussion}

> ## Exercise 3
> Use `begin` and `sync` statements to reproduce the functionality of `cobegin` in cobegin_example.chpl.
>> ## Solution
>> ~~~
>> var x=0;
>> writeln("This is the main thread, my value of x is ",x);
>>
>> sync
>> {
>>     begin
>>     {
>>        var x=5;
>>        writeln("this is task 1, my value of x is ",x);
>>     }
>>     begin writeln("this is task 2, my value of x is ",x);
>>  }
>>
>> writeln("this message won't appear until all tasks are done...");
>> ~~~
>> {:.source}
> {:.solution}
{:.challenge}

A more elaborated and powerful use of `sync` is as a type qualifier for variables. When a variable is declared as _sync_, a state that can be **_full_** or **_empty_** is associated to it.  

To assign a new value to a _sync_ variable,  its state must be _empty_ (after the assignment operation is completed, the state will be set as _full_). On the contrary, to read a value from a _sync_ variable, its state must be _full_ (after the read operation is completed, the state will be set as _empty_ again).

~~~
var x: sync int;
writeln("this is main task launching a new task");
begin {
  for i in 1..10 do writeln("this is new task working: ",i);
  x = 2;
  writeln("New task finished");
}

writeln("this is main task after launching new task... I will wait until  it is done");
x;
writeln("and now it is done");
~~~
{:.source}

~~~
>> chpl sync_example_2.chpl -o sync_example_2
>> ./sync_example_2
~~~
{:.input}

~~~
this is main task launching a new task
this is main task after launching new task... I will wait until  it is done
this is new task working: 1
this is new task working: 2
this is new task working: 3
this is new task working: 4
this is new task working: 5
this is new task working: 6
this is new task working: 7
this is new task working: 8
this is new task working: 9
this is new task working: 10
New task finished
and now it is done
~~~
{:.output}

> ## Discussion
> What would happen if we assign a value to _x_ right before launching the new task? What would happen if we assign a value to _x_ right before launching the new task and after the _writeln("and now it is done");_ statement? Discuss your observations
{:.discussion}

There are a number of methods defined for _sync_ variables. Suppose _x_ is a sync variable of a given type, 

~~~
// general methods
x.reset()	//will set the state as empty and the value as the default of x's type
x.isfull()	//will return true is the state of x is full, false if it is empty

//blocking read and write methods
x.writeEF(value)	//will block until the state of x is empty, 
			//then will assign the value,  and set the state to full 
x.writeFF(value)	//will block until the state of x is full, 
			//then will assign the value, and leave the state as full
x.readFE()		//will block until the state of x is full, 
			//then will return x's value, and set the state to empty
x.readFF()		//will block until the state of x is full, 
			//then will return x's value, and leave the state as full

//non-blocking read and write methods
x.writeXF(value)	//will assign the value no matter the state of x, and then set the state as full
x.readXX()		//will return the value of x regardless its state. The state will remain unchanged
~~~

Chapel also implements **_atomic_** operations with variables declared as `atomic`, and this provides another option to synchronize tasks. Atomic operations run completely independently of any other thread or process. This means that when several tasks try to write an atomic variable, only one will succeed at a given moment, providing implicit synchronization between them. There is a number of methods defined for atomic variables, among them `sub()`, `add()`, `write()`, `read()`, and `waitfor()` are very useful to establish explicit synchronization between tasks, as showed in the next code:

~~~
var lock: atomic int;
const numtasks=5;

lock.write(0);  //the main task set lock to zero

coforall id in 1..numtasks
{
    writeln("greetings form task ",id,"... I am waiting for all tasks to say hello");
    lock.add(1);				//task id says hello and atomically adds 1 to lock
    lock.waitFor(numtasks);			//then it waits for lock to be equal numtasks (which will happen when all tasks say hello)
    writeln("task ",id," is done...");
}
~~~
{:.source}

~~~
>> chpl atomic_example.chpl -o atomic_example
>> ./atomic_example
~~~
{:.input}

~~~
greetings form task 4... I am waiting for all tasks to say hello
greetings form task 5... I am waiting for all tasks to say hello
greetings form task 2... I am waiting for all tasks to say hello
greetings form task 3... I am waiting for all tasks to say hello
greetings form task 1... I am waiting for all tasks to say hello
task 1 is done...
task 5 is done...
task 2 is done...
task 3 is done...
task 4 is done...
~~~
{:.output}

> ## Try this...
> Comment out the line `lock.waitfor(numtasks)` in the code above to clearly observe the effect of the task synchronization.
{:.challenge}

Finally, with all the material studied so far, we should be ready to parallelize our code for the simulation of the heat transfer equation.

## Parallelizing the heat transfer equation

The parallelization of our base solution for the heat transfer equation can be achieved following the ideas of Exercise 2. The entire grid of points can be divided and assigned to multiple tasks. Each tasks should compute the new temperature of its assigned points, and then we must perform a **_reduction_**, over the whole grid, to update the greatest difference in temperature. 

For the reduction of the grid we can simply use the `max reduce` statement, which is already parallelized. Now, let's divide the grid into `rowtasks` x `coltasks` sub-grids, and assign each sub-grid to a task using the `coforall` loop (we will have `rowtasks*coltasks` tasks in total).

~~~
config const rowtasks=2;
config const coltasks=2;

//this is the main loop of the simulation
curdif=mindif;
while (c<niter && curdif>=mindif) do
{
  c+=1;     

  coforall taskid in 0..coltasks*rowtasks-1 do
  {
    for i in rowi..rowf do
    {
      for j in coli..colf do
      {
        temp[i,j]=(past_temp[i-1,j]+past_temp[i+1,j]+past_temp[i,j-1]+past_temp[i,j+1])/4;
      }
    }
  }

  curdif=max reduce (temp-past_temp);
  past_temp=temp;
  
  if c%n==0 then writeln('Temperature at iteration ',c,': ',temp[x,y]);
}
~~~
{:.source}

Note that now the nested for loops run from `rowi` to `rowf` and from `coli` to `colf` which are, respectively, the initial and final row and column of the sub-grid associated to the task `taskid`. To compute these limits, based on `taskid`, we can again follow the same ideas as in Exercise 2.

~~~
config const rowtasks=2;
config const coltasks=2;

const nr=rows/rowtasks;
const rr=rows-nr*rowtasks;
const nc=cols/coltasks;
const rc=cols-nc*coltasks;

//this is the main loop of the simulation
curdif=mindif;
while (c<niter && curdif>=mindif) do
{
  c+=1;     

  coforall taskid in 0..coltasks*rowtasks-1 do
  {
    var rowi, coli, rowf, colf: int;
    var taskr, taskc: int;

    taskr=taskid/coltasks;
    taskc=taskid%coltasks;

    if taskr<rr then
    {
      rowi=(taskr*nr)+1+taskr;
      rowf=(taskr*nr)+nr+taskr+1;
    }
    else
    {
      rowi=(taskr*nr)+1+rr;
      rowf=(taskr*nr)+nr+rr;
    }

    if taskc<rc then
    {
      coli=(taskc*nc)+1+taskc;
      colf=(taskc*nc)+nc+taskc+1;
    }
    else
    {
      coli=(taskc*nc)+1+rc;
      colf=(taskc*nc)+nc+rc;
    }

    for i in rowi..rowf do
    {
      for j in coli..colf do
      {
	  ...
	
}
~~~
{:.source}

As you can see, to divide a data set (the array `temp` in this case) between concurrent tasks, could be cumbersome. Chapel provides high-level abstractions for data parallelism that take care of all the data distribution for us. We will study data parallelism in the following lessons, but for now, let's compare the benchmark solution with our `coforall` parallelization to see how the performance improved. 

~~~
>> chpl --fast parallel_solution_1.chpl -o parallel1
>> ./parallel1 --rows=650 --cols=650 --x=200 --y=300 --niter=10000 --mindif=0.002 --n=1000
~~~
{:.input}

~~~
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
~~~
{:.output}

This parallel solution, using 4 parallel tasks, took around 17 seconds to finish. Compared with the ~20 seconds needed by the benchmark solution, seems not very impressive. To understand the reason, let's analyze the code's flow. When the program starts, the main thread does all the declarations and initializations, and then, it enters the main loop of the simulation (the **_while loop_**). Inside this loop, the parallel tasks are launched for the first time. When these tasks finish their computations, the main task resumes its execution, it updates `curdif`, and everything is repeated again. So, in essence, parallel tasks are launched and resumed 7750 times, which introduces a significant amount of overhead (the time the system needs to effectively start and destroy threads in the specific hardware, at each iteration of the while loop). 

Clearly, a better approach would be to launch the parallel tasks just once, and have them executing all the simulations, before resuming the main task to print the final results. 

~~~
config const rowtasks=2;
config const coltasks=2;

const nr=rows/rowtasks;
const rr=rows-nr*rowtasks;
const nc=cols/coltasks;
const rc=cols-nc*coltasks;

//this is the main loop of the simulation
curdif=mindif;
coforall taskid in 0..coltasks*rowtasks-1 do
{
  var rowi, coli, rowf, colf: int;
  var taskr, taskc: int;
  var c=0;

  taskr=taskid/coltasks;
  taskc=taskid%coltasks;

  if taskr<rr then
  {
    rowi=(taskr*nr)+1+taskr;
    rowf=(taskr*nr)+nr+taskr+1;
  }
  else
  {
    rowi=(taskr*nr)+1+rr;
    rowf=(taskr*nr)+nr+rr;
  }

  if taskc<rc then
  {
    coli=(taskc*nc)+1+taskc;
    colf=(taskc*nc)+nc+taskc+1;
  }
  else
  {
    coli=(taskc*nc)+1+rc;
    colf=(taskc*nc)+nc+rc;
  }

  while (c<niter && curdif>=mindif) do   
  {
    c=c+1;
    
    for i in rowi..rowf do
    {
      for j in coli..colf do
      {
        temp[i,j]=(past_temp[i-1,j]+past_temp[i+1,j]+past_temp[i,j-1]+past_temp[i,j+1])/4;
      }
    }
        
    //update curdif
    //update past_temp
    //print temperature in desired position
  }
}
~~~
{:.source}
    
The problem with this approach is that now we have to explicitly synchronize the tasks. Before, `curdif` and `past_temp` were updated only by the main task at each iteration; similarly, only the main task was printing results. Now, all these operations must be carried inside the coforall loop, which imposes the need of synchronization between tasks. 

The synchronization must happen at two points: 
1. We need to be sure that all tasks have finished with the computations of their part of the grid `temp`, before updating `curdif` and `past_temp` safely.
2. We need to be sure that all tasks use the updated value of `curdif` to evaluate the condition of the while loop for the next iteration.

To update `curdif` we could have each task computing the greatest difference in temperature in its associated sub-grid, and then, after the synchronization, have only one task reducing all the sub-grids' maximums.

~~~
var curdif: atomic real;
var myd: [0..coltasks*rowtasks-1] real;
...
//this is the main loop of the simulation
curdif.write(mindif);
coforall taskid in 0..coltasks*rowtasks-1 do
{
  var myd2: real;
  ...
  
  while (c<niter && curdif>=mindif) do   
  {
    c=c+1;
    ...
  
    for i in rowi..rowf do
    {
      for j in coli..colf do
      {
        temp[i,j]=(past_temp[i-1,j]+past_temp[i+1,j]+past_temp[i,j-1]+past_temp[i,j+1])/4;
        myd2=max(abs(temp[i,j]-past_temp[i,j]),myd2);
      }
    }
    myd[taskid]=myd2    
    
    //here comes the synchronization of tasks
    
    past_temp[rowi..rowf,coli..colf]=temp[rowi..rowf,coli..colf];
    if taskid==0 then
    {
      curdif.write(max reduce myd);
      if c%n==0 then writeln('Temperature at iteration ',c,': ',temp[x,y]);
    }
    
    //here comes the synchronization of tasks again
  }
}     
~~~
{:.source}

> ## Exercise 4
> Use `sync` or `atomic` variables to implement the synchronization required in the code above.
>> ## Solution
>> One possible solution is to use an atomic variable as a _lock_ that opens (using the `waitFor` method) when all the tasks complete the required instructions
>> ~~~
>> var lock: atomic int;
>> lock.write(0);
>> ...
>> //this is the main loop of the simulation
>> curdif.write(mindif);
>> coforall taskid in 0..coltasks*rowtasks-1 do
>> {
>>    ...
>>    while (c<niter && curdif>=mindif) do   
>>    {
>>       ...
>>       myd[taskid]=myd2    
>>
>>       //here comes the synchronization of tasks
>>       lock.add(1);
>>       lock.waitFor(coltasks*rowtasks);
>>       
>>       past_temp[rowi..rowf,coli..colf]=temp[rowi..rowf,coli..colf];
>>       ...
>>
>>       //here comes the synchronization of tasks again
>>       lock.sub(1);
>>       lock.waitFor(0);
>>    }
>> }
>> ~~~
>> {:.source} 
> {:.solution}
{:.challenge} 

Using the solution in the Exercise 4, we can now compare the performance with the benchmark solution

~~~
>> chpl --fast parallel_solution_2.chpl -o parallel2
>> ./parallel2 --rows=650 --cols=650 --x=200 --y=300 --niter=10000 --mindif=0.002 --n=1000
~~~
{:.input}

~~~
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
~~~
{:.output}

to see that we now have a code that performs 5x faster. 

We finish this section by providing another, elegant version of the task-parallel diffusion solver
(without time stepping) on a single locale:

~~~
const n = 100, stride = 20;
var T: [0..n+1, 0..n+1] real;
var Tnew: [1..n,1..n] real;
var x, y: real;
for (i,j) in {1..n,1..n} { // serial iteration
  x = ((i:real)-0.5)/n;
  y = ((j:real)-0.5)/n;
  T[i,j] = exp(-((x-0.5)**2 + (y-0.5)**2)/0.01); // narrow gaussian peak
}
coforall (i,j) in {1..n,1..n} by (stride,stride) { // 5x5 decomposition into 20x20 blocks => 25 tasks
  for k in i..i+stride-1 { // serial loop inside each block
    for l in j..j+stride-1 do {
      Tnew[i,j] = (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1]) / 4;
    }
  }
}
~~~
{:.source}
