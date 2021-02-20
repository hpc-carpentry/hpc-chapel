---
title: "Introduction to Chapel"
teaching: 15 
exercises: 15 
questions:
- "What is Chapel and why is it useful?"
objectives:
- "Write and execute our first chapel program."
keypoints:
- "Chapel is a compiled language - any programs we make must be compiled with `chpl`."
- "The `--fast` flag instructs the Chapel compiler to optimise our code."
- "The `-o` flag tells the compiler what to name our output (otherwise it gets named `a.out`)"
---

**_Chapel_** is a modern programming language, developed by _Cray Inc._, that
supports HPC via high-level abstractions for data parallelism and task
parallelism. These abstractions allow the users to express parallel codes in a
natural, almost intuitive, manner. In contrast with other high-level parallel
languages, however, Chapel was designed around a _multi-resolution_ philosophy.
This means that users can incrementally add more detail to their original code
prototype, to optimise it to a particular computer as closely as required.

In a nutshell, with Chapel we can write parallel code with the simplicity and
readability of scripting languages such as Python or MATLAB, but achieving
performance comparable to compiled languages like C or Fortran (+ traditional
parallel libraries such as MPI or OpenMP).

In this lesson we will learn the basic elements and syntax of the language;
then we will study **_task parallelism_**, the first level of parallelism in
Chapel, and finally we will use parallel data structures and **_data
parallelism_**, which is the higher level of abstraction, in parallel
programming, offered by Chapel.

## Getting started

Chapel is a compilable language which means that we must **_compile_** our
**_source code_** to generate a **_binary_** or **_executable_** that we can
then run in the computer.

Chapel source code must be written in text files with the extension
**_.chpl_**. Let's write a simple "hello world"-type program to demonstrate how
we write Chapel code! Using your favourite text editor, create the file
`hello.chpl` with the following content:

```
writeln('If we can see this, everything works!');
```
{: .bash}

This program can then be compiled with the following bash command:

~~~
chpl --fast hello.chpl -o hello.o
~~~
{: .bash}

The flag `--fast` indicates the compiler to optimise the binary to run as fast
as possible in the given architecture. The `-o` option tells Chapel what to
call the final output program, in this case `hello.o`.

To run the code, you execute it as you would any other program:

~~~
./hello.o
~~~
{: .bash}
```
If we can see this, everything works!
```
{: .output}

## Running on a cluster

Depending on the code, it might utilise several or even all cores on the
current node. The command above implies that you are allowed to utilise all
cores. This might not be the case on an HPC cluster, where a login node is
shared by many people at the same time, and where it might not be a good idea
to occupy all cores on a login node with CPU-intensive tasks.

On Compute Canada clusters Cedar and Graham we have two versions of Chapel, one
is a single-locale (single-node) Chapel, and the other is a multi-locale
(multi-node) Chapel. For now, we will start with single-locale Chapel. If you
are logged into Cedar or Graham, you'll need to load the single-locale Chapel
module:

~~~
module load gcc
module load chapel-single
~~~
{: .bash}

Then, for running a test code on a cluster you would submit an interactive job
to the queue

~~~
salloc --time=0:30:0 --ntasks=1 --cpus-per-task=3 --mem-per-cpu=1000 --account=def-guest
~~~
{: .bash}

and then inside that job compile and run the test code

~~~
chpl --fast hello.chpl -o hello.o
./hello.o
~~~
{: .bash}

For production jobs, you would compile the code and then submit a batch script
to the queue:

~~~
chpl --fast hello.chpl -o hello.o
sbatch script.sh
~~~
{: .bash}

where the script `script.sh` would set all Slurm variables and call the
executable `mybinary`.

## Case study

Along all the Chapel lessons we will be using the following _case study_ as the
leading thread of the discussion. Essentially, we will be building, step by
step, a Chapel code to solve the **_Heat transfer_** problem described below.
Then we will parallelize the code to improve its performance.

Suppose that we have a square metallic plate with some initial heat
distribution or **_initial conditions_**. We want to simulate the evolution of
the temperature across the plate when its border is in contact with a different
heat distribution that we call the **_boundary conditions_**.

The Laplace equation is the mathematical model for the evolution of the
temperature in the plate. To solve this equation numerically, we need to
**_discretise_** it, i.e. to consider the plate as a grid, or matrix of points,
and to evaluate the temperature on each point at each iteration, according to
the following **_difference equation_**:

```
T[i,j] = 0.25 (Tp[i-1,j] + Tp[i+1,j] + Tp[i,j-1] + Tp[i,j+1])
```
{: .source}

Here `T` stands for the temperature at the current iteration, while `Tp`
contains the temperature calculated at the past iteration (or the initial
conditions in case we are at the first iteration). The indices `i` and `j`
indicate that we are working on the point of the grid located at the *i*th row
and the *j*th column.

So, our objective is to:

> ## Goals
> 1. Write a code to implement the difference equation above.The code should
>    have the following requirements:
>
>    * It should work for any given number of rows and columns in the grid.
>    * It should run for a given number of iterations, or until the difference
>      between `T` and `Tp` is smaller than a given tolerance value.
>    * It should output the temperature at a desired position on the grid every
>      given number of iterations.
>
> 2. Use task parallelism to improve the performance of the code and run it in
>    the cluster
> 3. Use data parallelism to improve the performance of the code and run it in
>    the cluster.
{: .checklist}
