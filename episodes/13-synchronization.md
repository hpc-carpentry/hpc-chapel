---
title: "Synchronising tasks"
teaching: 60
exercises: 30
---

:::::::::::::::::::::::::::::::::::::: questions
- "How should I access my data in parallel?"
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives
- "First objective."
::::::::::::::::::::::::::::::::::::::::::::::::

The keyword `sync` provides all sorts of mechanisms to synchronise tasks in Chapel.

We can simply use `sync` to force the _parent_ task to stop and wait until its _spawned-child-task_ ends.

```chpl
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
```

```bash
chpl sync_example_1.chpl
./sync_example_1 
```

```output
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
```

::::::::::::::::::::::::::::::::::::::: discussion

## Discussion

What would happen if we write instead

```chpl
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
```

:::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 3: Can you do it?

Use `begin` and `sync` statements to reproduce the functionality of `cobegin` in `cobegin_example.chpl`.

:::::::::::::::::::::::: solution

```chpl
var x=0;
writeln("This is the main thread, my value of x is ",x);

sync
{
    begin
    {
       var x=5;
       writeln("this is task 1, my value of x is ",x);
    }
    begin writeln("this is task 2, my value of x is ",x);
 }

writeln("this message won't appear until all tasks are done...");
```

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

A more elaborated and powerful use of `sync` is as a type qualifier for variables. When a variable is declared
as _sync_, a state that can be **_full_** or **_empty_** is associated to it.

To assign a new value to a _sync_ variable, its state must be _empty_ (after the assignment operation is
completed, the state will be set as _full_). On the contrary, to read a value from a _sync_ variable, its
state must be _full_ (after the read operation is completed, the state will be set as _empty_ again).

```chpl
var x: sync int, a: int;
writeln("this is main task launching a new task");
begin {
  for i in 1..10 do writeln("this is new task working: ",i);
  x = 2;
  writeln("New task finished");
}

writeln("this is main task after launching new task... I will wait until  it is done");
a = x;   // don't run this line until the variable x is written in the other task
writeln("and now it is done");
```

```bash
chpl sync_example_2.chpl
./sync_example_2
```

```output
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
```

::::::::::::::::::::::::::::::::::::::: discussion

## Discussion

What would happen if we assign a value to _x_ right before launching the new task? What would happen if we
assign a value to _x_ right before launching the new task and after the _writeln("and now it is done");_
statement?

Discuss your observations.

:::::::::::::::::::::::::::::::::::::::::::::::::::

There are a number of methods defined for _sync_ variables. Suppose _x_ is a sync variable of a given type,

```chpl
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
```

Chapel also implements **_atomic_** operations with variables declared as `atomic`, and this provides another
option to synchronise tasks. Atomic operations run completely independently of any other thread or
process. This means that when several tasks try to write an atomic variable, only one will succeed at a given
moment, providing implicit synchronisation between them.  There is a number of methods defined for atomic
variables, among them `sub()`, `add()`, `write()`, `read()`, and `waitfor()` are very useful to establish
explicit synchronisation between tasks, as showed in the next code:

```chpl
var lock: atomic int;
const numtasks=5;

lock.write(0);  //the main task set lock to zero

coforall id in 1..numtasks
{
    writeln("greetings from task ",id,"... I am waiting for all tasks to say hello");
    lock.add(1);                //task id says hello and atomically adds 1 to lock
    lock.waitFor(numtasks);     //then it waits for lock to be equal numtasks (which will happen when all tasks say hello)
    writeln("task ",id," is done...");
}
```

```bash
chpl atomic_example.chpl
./atomic_example
```

```output
greetings from task 4... I am waiting for all tasks to say hello
greetings from task 5... I am waiting for all tasks to say hello
greetings from task 2... I am waiting for all tasks to say hello
greetings from task 3... I am waiting for all tasks to say hello
greetings from task 1... I am waiting for all tasks to say hello
task 1 is done...
task 5 is done...
task 2 is done...
task 3 is done...
task 4 is done...
```

> ## Try this...
>
> Comment out the line `lock.waitfor(numtasks)` in the code above to clearly observe the effect of the task
> synchronisation.

Finally, with all the material studied so far, we should be ready to parallelize our code for the simulation
of the heat transfer equation.

::::::::::::::::::::::::::::::::::::: keypoints
- "You can explicitly synchronise tasks with `sync` statement."
- "You can also use sync and atomic variables to synchronise tasks."
::::::::::::::::::::::::::::::::::::::::::::::::
