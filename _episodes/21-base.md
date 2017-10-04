---
title: "Chapel Base Language"
teaching: 60
exercises: 30
questions:
- "Key question"
objectives:
- "First objective."
keypoints:
- "First key point."
---

**_Chapel_** is a modern programming language, developed by _Cray Inc._, that supports HPC via high-level abstractions for data parallelism and task parallelism. These abstractions allow the users to express parallel codes in a natural, almost intuitive, manner. In contrast with other high-level parallel languages, however, Chapel was designed around a _multi-resolution_ philosophy. This means that users can incrementally add more detail to their original abstract code prototype, to bring it as close to the machine as required. 

In a nutshell, with Chapel we can write parallel codes with the simplicity and readability of scripting languages such as Python or Matlab, but achieving performance comparable to lower-level compilable languages such as C or Fortran (+ traditional parallel libraries such as MPI or openMP).

Chapel is a compilable language which means that we must **_compile_** our **_source code_** to generate a **_binary_** or **_executable_** that we can then run in the computer. 

Chapel source code must be written in text files with the extension **_.chpl_**. The basic compilation of a source code `mycode.chpl` to generate an executable `mybinary` can be done as follows:

~~~
>> chpl --fast mycode.chpl -o mybinary
~~~
{:.input}

The flag `--fast` indicates the compiler to optimize the binary to run as fast as possible in the given architecture.

Chapel was designed from scratch as a new programming language. It is an imperative language with its own syntax (with elements similar to C) that we must know before introducing the parallel programming concepts. 

In this lesson we will learn the basic elements and syntax of the language; then we will study **_task parallelism_**, the first level of parallelism in Chapel, and finally we will use parallel data structures and **_data parallelism_**, which is the higher level of abstraction, in parallel programming, offered by Chapel. 

To run the code, you can simply type:

~~~
>> ./mybinary
~~~
{:.input}

Depending on the code, it might utilize several or even all cores on the current node. The command above
implies that you are allowed to utilize all cores. This might not be the case on an HPC cluster, where a
login node is shared by many people at the same time, and where it might not be a good idea to occupy all
cores on a login node with CPU-intensive tasks.

On Compute Canada clusters Cedar and Graham we have two versions of Chapel, one is a single-locale
(single-node) Chapel, and the other is a multi-locale (multi-node) Chapel. For now, we will start with
single-locale Chapel. If you are logged into Cedar or Graham, you'll need to load the single-locale
Chapel module:

~~~
>> module load gcc
>> module load chapel-single/1.15.0
~~~
{:.input}

Then, for running a test code on a cluster you would submit an interactive job to the queue

~~~
>> salloc --time=0:30:0 --ntasks=1 --cpus-per-task=3 --mem-per-cpu=1000 --account=def-guest
~~~
{:.input}

and then inside that job compile and run the test code

~~~
>> chpl --fast mycode.chpl -o mybinary
>> ./mybinary
~~~
{:.input}

For production jobs, you would compile the code and then submit a batch script to the queue:

~~~
>> chpl --fast mycode.chpl -o mybinary
>> sbatch script.sh
~~~
{:.input}

where the script `script.sh` would set all Slurm variables and call the executable `mybinary`.

### Case study

Along all the Chapel lessons we will be using the following _case study_ as the leading thread of the discussion. Essentially, we will be building, step by step, a Chapel code to solve the **_Heat transfer_** problem described bellow. Then we will parallelize the code to improve its performance. 

Suppose that we have a square metallic plate with some initial heat distribution or **_initial conditions_**. We want to simulate the evolution of the temperature across the plate when its border is in contact with a different heat distribution that we call the **_boundary conditions_**. 

The Laplace equation is the mathematical model for the evolution of the temperature in the plate. To solve this equation numerically, we need to **_discretize_** it, i.e. to consider the plate as a grid, or matrix of points, and to evaluate the temperature on each point at each iteration, according to the following **_difference equation_**:

```
T[i,j] = 0.25 (Tp[i-1,j] + Tp[i+1,j] + Tp[i,j-1] + Tp[i,j+1])
```
Here T stands for the temperature at the current iteration, while Tp contains the temperature calculated at the past iteration (or the initial conditions in case we are at the first iteration). The indices i and j indicate that we are working on the point of the grid located at the i-th row and the j-th column. 

So, our objective is to:

> ## Goals
> 1. Write a code to implement the difference equation above.The code should have the following requirements: a)  it should work for any given number of rows and columns in the grid, b) it should run for a given number of iterations, or until the difference between T and Tp is smaller than a given tolerance value, and c) it should output the temperature at a desired position on the grid every given number of iterations. 
> 2. Use task parallelism to improve the performance of the code and run it in the cluster
> 3. Use data parallelism to improve the performance of the code and run it in the cluster.
{:.checklist}

## Variables

Variables in programming are not the same as the mathematical concept. In programming, a variable is an allocated space in the memory of the computer, where we can store information or data while executing a program. A variable has three elements: 
1. a **_name_** or label, to identify the variable 
2. a **_type_**, that indicates the kind of data that we can store in it, and
3. a **_value_**, the actual information or data stored in the variable.

When we store a value in a variable for the first time, we say that we **_initialized_** it. Further changes to the value of a variable are called **_assignments_**, in general, `x=a` means that we assign the value *a* to the variable *x*.

Now, let's start by declaring the variables that we will need for our simulation. 

Variables in Chapel are declared with the `var` or `const` keywords. When a variable declared as const is initialized, its value cannot be modified anymore during the execution of the program. 

In Chapel, to declare a variable we must specify the type of the variable, or initialize it in place with some value. The common variable types in Chapel are:
* integer `int`, 
* floating point number `real`, 
* boolean `bool`, or 
* srting `string`


If a variable is declared without a type, Chapel will infer it from the given initial value, for example:

~~~
const rows=100;		//number of rows in matrix
const cols=100;		//number of columns in matrix
const niter=500;	//number of iterations
const x=50;		//row number of the desired position
const y=50;		//column number of the desired position
~~~
{:.source}

all this constant variables will be created as integers, and initialized with the corresponding values. No other values can be assigned to these variables during the execution of the program.

On the other hand, if a variable is declared without an initial value, Chapel will initialize it with a defualt value depending on the declared type (0.0 for real variables, for example). The followoing variables will be created as real floating point numbers equal to 0.0.

~~~
var curdif: real;	//here we will store the greatest difference in temperature from one iteration to another 
var tt: real;		//for temporary results when computing the temperatures
~~~
{:.source}

Of course, we can use both, the initial value and the type, when declaring a varible as follows:

~~~
const mindif=0.0001: real;	//smallest difference in temperature that would be accepted before stoping
var c=0: int;			//this is the iteration counter
const n=20: int;		//the temperature at the desired position will be printed every n interations
~~~
{:.source}

*This is not necessary, but it could help to make the code more readable.*

## Ranges and Arrays

A series of integers (1,2,3,4,5, for example), is called a **_range_**. Ranges are generated with the `..` operator, and are useful, among other things, to declare **_arrays_** of variables. For example, the following variables

~~~
var past_temp: [0..rows+1,0..cols+1] real;	//here we will store the matrix of temperatures in the last iteration
var temp: [0..rows+1,0..cols+1] real;		//here we will store the new temperatures calculated at the current iteration
~~~
{:.source}

are matrices -2D arrays- with (`rows + 2`) rows and (`cols + 2`) columns of real numbers, all initialized as 0.0. The ranges `0..rows+1` and `0..cols+1` used here, not only define the size and shape of the array, they stand for the indices with which we could access particular elements of the array using the `[ , ]` notation. For example, `temp[0,0]` is the real variable located at the frist row and first column of the array `temp`, while `temp[3,7]` is the one at the 4th row and 8th column; `temp[2,3..15]` access columns 4th to 16th of the 3th row of `temp`, and `temp[0..3,4]` corresponds to the first 4 rows on the 5th column of `temp`. Similarly, with

~~~
//this setup some initial conditions
past_temp[1..rows,1..cols]=25;     //set an initial tempertature (iteration 0) 
~~~
{:.source}

we assign an initial temperature of 25 degrees across all points of our metal plate.

image: to show the matrices and its indices

We must now be ready to start coding our simulations... but first, let's print some information about the initial configuration, compile the code, and execute it to see if everything is working as expected.

~~~
writeln('\nThis simulation will consider a matrix of ',rows,' by ',cols,' elements,');
writeln('it will run up to ',niter,' iterations, or until the largest difference\n in temperature is less than ',mindif,'.');
writeln('You are interested in the evolution of the temperature at the position (',x,',',y,') of the matrix...\n');
writeln('and here we go...');
writeln('Temperature at iteration ',c,': ',past_temp[x,y]);
~~~
{:.source}

~~~
>> chpl base_solution.chpl -o base_solution
>> ./base_solution
~~~
{:.input}

~~~
This simulation will consider a matrix of 100 by 100 elements,
it will run up to 500 iterations, or until the largest difference
in temperature between iterations is less than 0.001.
You are interested in the evolution of the temperature at the position (50,50) of the matrix...

and here we go...
Temperature at iteration 0: 25.0
~~~
{:.output}

Note that each `writeln` statement starts a new line, but we can also introduce new lines using `\n` within the text.


## Conditional statements

Chapel, as most *high level programming languages*, has different staments to control the flow of the program or code.  The conditional statements are: the **_if statement_**, and the **_while statement_**. 

The general syntax of a while statement is: 

```
while condition do 
{instructions}
```

The code flows as follows: first, the condition is evaluated, and then, if it is satisfied, all the instructions within the curly brackets are executed one by one. This will be repeated over and over again until the condition does not hold anymore.

The main loop in our simulation can be programmed using a while statement like this

~~~
//this is the main loop of the simulation
curdif=mindif;
while (c<niter && curdif>=mindif) do
{
  c+=1;     //increse the number of iterations by one
  //calculate the new temperatures (temp) using the past temperatures (past_temp)
  //update curdif, the greatest difference between temp and past_temp
  //print the temperature at the desired position if the iteration is multiple of n
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

So, in our case

~~~
//print the temperature at the desired position if the iteration is multiple of n
if c%20==0 then writeln('Temperature at iteration ',c,': ',temp[x,y]);
~~~
{:.source}

will do the trick. Note that when only one instruction will be executed, there is no need to use the curly brackets. `%` is the modulo operator, it returns the remainder after the division (i.e. it returns zero when `c` is multiple of 20). 

Let's compile and execute our code to see what we get until now

~~~
>> chpl base_solution.chpl -o base_solution
>> ./base_solution
~~~
{:.input}

~~~
This simulation will consider a matrix of 100 by 100 elements,
it will run up to 500 iterations, or until the largest difference
in temperature between iterations is less than 0.0001.
You are interested in the evolution of the temperature at the position (50,50) of the matrix...

and here we go...
Temperature at iteration 0: 25.0
Temperature at iteration 20: 0.0
Temperature at iteration 40: 0.0
Temperature at iteration 60: 0.0
Temperature at iteration 80: 0.0
Temperature at iteration 100: 0.0
Temperature at iteration 120: 0.0
Temperature at iteration 140: 0.0
Temperature at iteration 160: 0.0
Temperature at iteration 180: 0.0
Temperature at iteration 200: 0.0
Temperature at iteration 220: 0.0
Temperature at iteration 240: 0.0
Temperature at iteration 260: 0.0
Temperature at iteration 280: 0.0
Temperature at iteration 300: 0.0
Temperature at iteration 320: 0.0
Temperature at iteration 340: 0.0
Temperature at iteration 360: 0.0
Temperature at iteration 380: 0.0
Temperature at iteration 400: 0.0
Temperature at iteration 420: 0.0
Temperature at iteration 440: 0.0
Temperature at iteration 460: 0.0
Temperature at iteration 480: 0.0
Temperature at iteration 500: 0.0
~~~
{:.output}

Of course the temperature is always 0.0 at any iteration other than the initial one, as we haven't done any computation yet.


## Structured iterations with for-loops

To compute the current temperature of an element of `temp`, we need to add all the surronding elements in `past_temp`, and divide the result by 4. And, esentially, we need to repeat this process for all the elements of `temp`, or, in other words, we need to *iterate* over the elements of `temp`. When it comes to iterate over a given number of elements, the **_for-loop_** is what we want to use. The for-loop has the following general syntax: 

```
for index in iterand do
{instructions}
``` 

The *iterand* is a function or statement that expresses an iteration; it could be the range 1..15, for example. *index* is a variable that exists only in the context of the for-loop, and that will be taking the different values yielded by the iterand. The code flows as follows: index takes the first value yielded by the iterand, and keeps it until all the instructions inside the curly brackets are executed one by one; then, index takes the second value yielded by the iterand, and keeps it until all the instructions are executed again. This pattern is repeated until index takes all the different values exressed by the iterand.

This for loop, for example

~~~
//calculate the new current temperatures (temp) using the past temperatures (past_temp)
for i in 1..rows do   
{
  //do this for every row 
}
~~~
{:.source}

will allow us to iterate over the rows of `temp`. Now, for each row we also need to iterate over all the columns in order to access every single element of `temp`. This can be done with nested for loops like this

~~~
//calculate the new current temperatures (temp) using the past temperatures (past_temp)
for i in 1..rows do   
{
  //do this for every row 
  for j in 1..cols do
  {
    //and this for every column in the row i
  }
}     
~~~
{:.source}

Now, inside the inner loop, we can use the indices `i` and `j` to perform the required computations as follows:

~~~
//calculate the new current temperatures (temp) using the past temperatures (past_temp)
for i in 1..rows do   
{
  //do this for every row 
  for j in 1..cols do
  {
    //and this for every column in the row i
    temp[i,j]=(past_temp[i-1,j]+past_temp[i+1,j]+past_temp[i,j-1]+past_temp[i,j+1])/4;
  }
}     
past_temp=temp
~~~
{:.source}

Note that at the end of the outer for-loop, when all the elements in `temp` are already calculated, we update `past_temp` with the values of `temp`; this way everything is set up for the next iteration of the main while statement.

Now let's compile and execute our code again:

~~~
>> chpl base_solution.chpl -o base_solution
>> ./base_solution
~~~
{:.input}

~~~
The simulation will consider a matrix of 100 by 100 elements,
it will run up to 500 iterations, or until the largest difference
in temperature between iterations is less than 0.0001.
You are interested in the evolution of the temperature at the position (50,50) of the matrix...

and here we go...
Temperature at iteration 0: 25.0
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
Temperature at iteration 220: 24.9999
Temperature at iteration 240: 24.9996
Temperature at iteration 260: 24.9991
Temperature at iteration 280: 24.9981
Temperature at iteration 300: 24.9963
Temperature at iteration 320: 24.9935
Temperature at iteration 340: 24.9893
Temperature at iteration 360: 24.9833
Temperature at iteration 380: 24.9752
Temperature at iteration 400: 24.9644
Temperature at iteration 420: 24.9507
Temperature at iteration 440: 24.9337
Temperature at iteration 460: 24.913
Temperature at iteration 480: 24.8883
Temperature at iteration 500: 24.8595
~~~
{:.output}

As we can see, the temperature in the middle of the plate (position 50,50) is slowly decreasing as the plate is cooling down. 

> ## Excercise 1
> What would be the temperature at the top right corner of the plate? The border of the plate is in contact with the boundary conditions, which are set to zero, so we expect the temperature at these points to decrease faster. Modify the code to see the temperature at the top right corner.
>> ## Solution
>> To see the evolution of the temperature at the top right corner of the plate, we just need to modify `x` and `y`. This corner correspond to the first row (`x=1`) and the last column (`y=cols`) of the plate. 
>> ~~~
>> >> chpl base_solution.chpl -o base_solution
>> >> ./base_solution
>> ~~~
>> {:.input}
>> ~~~
>> The simulation will consider a matrix of 100 by 100 elements,
>> it will run up to 500 iterations, or until the largest difference
>> in temperature between iterations is less than 0.0001.
>> You are interested in the evolution of the temperature at the position (1,100) of the matrix...
>> 
>> and here we go...
>> Temperature at iteration 0: 25.0
>> Temperature at iteration 20: 1.48171
>> Temperature at iteration 40: 0.767179
>> ...
>> Temperature at iteration 460: 0.068973
>> Temperature at iteration 480: 0.0661081
>> Temperature at iteration 500: 0.0634717
>> ~~~
>> {:.output}
> {:.solution}
{:.challenge}

> ## Exercise 2
> Now let's have some more interesting boundary conditions. Suppose that the plate is heated by a source of 80 degrees located at the bottom right corner, and that the temperature on the rest of the border decreases linearly as one gets farther form the corner (see the image bellow). Utilize for loops to setup the described boundary conditions. Compile and run your code to see how the temperature is changing now. 
>> ## Solution
>> To get the linear distribution, the 80 degrees must be divided by the number of rows or columns in our plate. So, the following couple of for loops will give us what we want;
>> ~~~
>> //this setup the boundary conditions
>> for i in 1..rows do
>> {
>>   past_temp[i,cols+1]=i*80.0/rows;
>>   temp[i,cols+1]=i*80.0/rows;
>> }
>> for j in 1..cols do
>> {
>>   past_temp[rows+1,j]=j*80.0/cols;
>>   temp[rows+1,j]=j*80.0/cols;
>> }
>> ~~~
>> {:.source}
>> Note that the boundary conditions must be set in both arrays, `past_temp` and `temp`, otherwise, they will be set to zero again after the first iteration. Also note that 80 degrees are written as a real number 80.0. The division of integers in Chapel returns an integer, then, as `rows` and `cols` are integers, we must have 80 as real so that the cocient is not truncated. 
>> ~~~
>> >> chpl base_solution.chpl -o base_solution
>> >> ./base_solution
>> ~~~
>> {:.input}
>> ~~~
>> The simulation will consider a matrix of 100 by 100 elements,
>> it will run up to 500 iterations, or until the largest difference
>> in temperature between iterations is less than 0.0001.
>> You are interested in the evolution of the temperature at the position (1,100) of the matrix...
>> 
>> and here we go...
>> Temperature at iteration 0: 25.0
>> Temperature at iteration 20: 2.0859
>> Temperature at iteration 40: 1.42663
>> ...
>> Temperature at iteration 460: 0.826941
>> Temperature at iteration 480: 0.824959
>> Temperature at iteration 500: 0.823152
>> ~~~
>> {:.output}
> {:.solution}
{:.challenge}

> ## Exercise 3
> So far, `curdif` has been always equal to `mindif`, which means that our main while loop will always run the 500 iterations. So let's update `curdif` after each iteration. Use what we have studied so far to write the required piece of code.
>> ## Solution
>> The idea is simple, after each iteration of the while loop, we must compare all elements of `temp` and `past_temp`, find the greatest difference, and update `curdif` with that value. The next nested for loops do the job:
>> ~~~
>> //update curdif, the greatest difference between temp and past_temp
>> curdif=0;
>> for i in 1..rows do
>> {
>>   for j in 1..cols do
>>   {
>>     tt=temp[i,j]-past_temp[i,j];
>>     if tt>curdif then curdif=tt;
>>   }
>> }
>> ~~~
>> {:.source}
>> Clearly there is no need to keep the difference at every single position in the array, we just need to update `curdif` if we find a greater one. 
>> ~~~
>> >> chpl base_solution.chpl -o base_solution
>> >> ./base_solution
>> ~~~
>> {:.input}
>> ~~~
>> The simulation will consider a matrix of 100 by 100 elements,
>> it will run up to 500 iterations, or until the largest difference
>> in temperature between iterations is less than 0.0001.
>> You are interested in the evolution of the temperature at the position (1,100) of the matrix...
>> 
>> and here we go...
>> Temperature at iteration 0: 25.0
>> Temperature at iteration 20: 2.0859
>> Temperature at iteration 40: 1.42663
>> ...
>> Temperature at iteration 460: 0.826941
>> Temperature at iteration 480: 0.824959
>> Temperature at iteration 500: 0.823152
>> ~~~
>> {:.output}
> {:.solution}
{:.challenge}

Now, after Excercise 3 we should have a working program to simulate our heat transfer equation. Let's just print some additional useful information,

~~~
//print final information
writeln('\nFinal temperature at the desired position after ',c,' iterations is: ',temp[x,y]);
writeln('The difference in temperatures between the last two iterations was: ',curdif,'\n');
~~~
{:.source}

and compile and execute our final code,

~~~
>> chpl base_solution.chpl -o base_solution
>> ./base_solution
~~~
{:.input}

~~~
The simulation will consider a matrix of 100 by 100 elements,
it will run up to 500 iterations, or until the largest difference
in temperature between iterations is less than 0.0001.
You are interested in the evolution of the temperature at the position (1,100) of the matrix...

and here we go...
Temperature at iteration 0: 25.0
Temperature at iteration 20: 2.0859
Temperature at iteration 40: 1.42663
Temperature at iteration 60: 1.20229
Temperature at iteration 80: 1.09044
Temperature at iteration 100: 1.02391
Temperature at iteration 120: 0.980011
Temperature at iteration 140: 0.949004
Temperature at iteration 160: 0.926011
Temperature at iteration 180: 0.908328
Temperature at iteration 200: 0.894339
Temperature at iteration 220: 0.88302
Temperature at iteration 240: 0.873688
Temperature at iteration 260: 0.865876
Temperature at iteration 280: 0.85925
Temperature at iteration 300: 0.853567
Temperature at iteration 320: 0.848644
Temperature at iteration 340: 0.844343
Temperature at iteration 360: 0.840559
Temperature at iteration 380: 0.837205
Temperature at iteration 400: 0.834216
Temperature at iteration 420: 0.831537
Temperature at iteration 440: 0.829124
Temperature at iteration 460: 0.826941
Temperature at iteration 480: 0.824959
Temperature at iteration 500: 0.823152

Final temperature at the desired position after 500 iterations is: 0.823152
The greatest difference in temperatures between the last two iterations was: 0.0258874
~~~
{:.output}

## Using command line arguments 

From the last run of our code, we can see that 500 iterations is not enough to get to a _steady state_ (a state where the difference in temperature does not vary too much, i.e. `curdif`<`mindif`). Now, if we want to change the number of iterations we would need to modify `niter` in the code, and compile it again. What if we want to change the number of rows and columns in our grid to have more precision?, or if we want to see the evolution of the temperature at a different point (x,y). The answer would be the same, modify the code and compile it again!

No need to say that this would be very tedious and inefficient. A better scenario would be if we can pass the desired configuration values to our binary when it is called at the command line. The Chapel mechanism to this effect is the use of **_config_** variables. When a variable is declared with the `config` keyword, in addition to `var` or `const`, like this:

~~~
config const niter=500;    //number of iterations
~~~
{:.source}

~~~
>> chpl base_solution.chpl -o base_solution
~~~
{:.input}

it can be inicialized with a specific value, when executing the code at the command line, using the syntax:

~~~
>> ./base_solution --niter=3000
~~~
{:.input}

~~~
The simulation will consider a matrix of 100 by 100 elements,
it will run up to 3000 iterations, or until the largest difference
in temperature between iterations is less than 0.0001.
You are interested in the evolution of the temperature at the position (1,100) of the matrix...

and here we go...
Temperature at iteration 0: 25.0
Temperature at iteration 20: 2.0859
Temperature at iteration 40: 1.42663
...
Temperature at iteration 2980: 0.793969
Temperature at iteration 3000: 0.793947

Final temperature at the desired position after 3000 iterations is: 0.793947
The greatest difference in temperatures between the last two iterations was: 0.000350086
~~~
{:.output}

> ## Excercise 4
> Make `n`, `x`, `y`, `mindif`, `rows` and `cols` configurable variables, and test the code simulating different configurations. What can you conclude about the performance of the code.
>> ## Solution
>> For example, lets use a 650 x 650 grid and observe the evolution of the temperature at the position (200,300) for 10000 iterations or until the difference of temperature between iterations is less than 0.002; also, let's print the temperature every 1000 iterations.
>> ~~~
>> >> ./base_solution --rows=650 --cols=650 --x=200 --y=300 --niter=10000 --mindif=0.002 --n=1000
>> ~~~
>> {:.input}
>> ~~~
>> The simulation will consider a matrix of 650 by 650 elements,
>> it will run up to 10000 iterations, or until the largest difference
>> in temperature between iterations is less than 0.002.
>> You are interested in the evolution of the temperature at the position (200,300) of the matrix...
>>
>> and here we go...
>> Temperature at iteration 0: 25.0
>> Temperature at iteration 1000: 25.0
>> Temperature at iteration 2000: 25.0
>> Temperature at iteration 3000: 25.0
>> Temperature at iteration 4000: 24.9998
>> Temperature at iteration 5000: 24.9984
>> Temperature at iteration 6000: 24.9935
>> Temperature at iteration 7000: 24.9819
>>
>> Final temperature at the desired position after 7750 iterations is: 24.9671
>> The greatest difference in temperatures between the last two iterations was: 0.00199985
>> ~~~
>> {:.output}
> {:.solution}
{:.challenge}

## Timing the execution of code in Chapel

The code generated after Excercise 4 is the basic implementation of our simulation. We will be using it as a benchmark, to see how much we can improve the performance when introducing the parallel programming features of the language in the following lessons. 

But first, we need a quantitative way to measure the performance of our code. Maybe the easiest way to do it, is to see how much it takes to finish a simulation. The UNIX command `time` could be used to this effect

~~~
>> time ./base_solution --rows=650 --cols=650 --x=200 --y=300 --niter=10000 --mindif=0.002 --n=1000
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

Final temperature at the desired position after 7750 iterations is: 24.9671
The greatest difference in temperatures between the last two iterations was: 0.00199985


real	0m20.381s
user	0m20.328s
sys	0m0.053s
~~~
{:.output}

The real time is what interest us. Our code is taking around 34 seconds from the moment it is called at the command line until it returns. Some times, however, it could be useful to take the execution time of specific parts of the code. This can be achieved by modifying the code to output the information that we need. This process is called **_instrumentation of code_**.

An easy way to instrument our code with Chapel is by using the module `Time`. **_Modules_** in Chapel are libraries of useful functions and methods that can be used in or code once the module is loaded. To load a module we use the keyword `use` followed by the name of the module. Once the Time module is loaded we can create a variable of the type `Timer`, and use the methods `start`,`stop`and `elapsed` to instrument our code.

~~~
use Time;
var watch: Timer;
watch.start();

//this is the main loop of the simulation
curdif=mindif;
while (c<niter && curdif>=mindif) do
{
...
}

watch.stop();

//print final information
writeln('\nThe simulation took ',watch.elapsed(),' seconds');
writeln('Final temperature at the desired position after ',c,' iterations is: ',temp[x,y]);
writeln('The greatest difference in temperatures between the last two iterations was: ',curdif,'\n');
~~~
{:.source}

~~~
>> chpl base_solution.chpl -o base_solution
>> ./base_solution --rows=650 --cols=650 --x=200 --y=300 --niter=10000 --mindif=0.002 --n=1000
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

The simulation took 20.1621 seconds
Final temperature at the desired position after 7750 iterations is: 24.9671
The greatest difference in temperatures between the last two iterations was: 0.00199985
~~~
{:.output}
