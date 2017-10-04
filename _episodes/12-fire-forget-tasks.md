---
title: "Fire-and-forget tasks"
teaching: 60
exercises: 30
questions:
- "How do execute work in parallel?"
objectives:
- "First objective."
keypoints:
- "First key point."
---

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