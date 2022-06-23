---
title: "Running code on multiple machines"
teaching: 120
exercises: 60
questions:
- "What is a locale?"
objectives:
- "First objective."
keypoints:
- "Locale in Chapel is a shared-memory node on a cluster."
- "We can cycle in serial or parallel through all locales."
---

So far we have been working with single-locale Chapel codes that may run on one
or many cores on a single compute node, making use of the shared memory space
and accelerating computations by launching concurrent tasks on individual cores
in parallel. Chapel codes can also run on multiple nodes on a compute cluster.
In Chapel this is referred to as *multi-locale* execution.

If you work inside a Chapel Docker container, e.g., chapel/chapel-gasnet, the
container environment simulates a multi-locale cluster, so you would compile
and launch multi-locale Chapel codes directly by specifying the number of
locales with `-nl` flag:

~~~
$ chpl --fast mycode.chpl -o mybinary
$ ./mybinary -nl 4
~~~
{:.bash}

Inside the Docker container on multiple locales your code will not run any
faster than on a single locale, since you are emulating a virtual cluster, and
all tasks run on the same physical node. To achieve actual speedup, you need to
run your parallel multi-locale Chapel code on a real physical cluster which we
hope you have access to for this session.

On a real HPC cluster you would need to submit either an interactive or a batch
job asking for several nodes and then run a multi-locale Chapel code inside
that job. In practice, the exact commands depend on how the multi-locale Chapel
was built on the cluster.

When you compile a Chapel code with the multi-locale Chapel compiler, two
binaries will be produced. One is called `mybinary` and is a launcher binary
used to submit the real executable `mybinary_real`. If the Chapel environment
is configured properly with the launcher for the cluster's physical
interconnect (which might not be always possible due to a number of factors),
then you would simply compile the code and use the launcher binary `mybinary`
to submit the job to the queue:

~~~
$ chpl --fast mycode.chpl -o mybinary
$ ./mybinary -nl 2
~~~
{: .bash}

The exact parameters of the job such as the maximum runtime and the requested
memory can be specified with Chapel environment variables. One possible drawback of this
launching method is that, depending on your cluster setup, Chapel might have access to all physical cores on each
node participating in the run -- this will present problems if you are
scheduling jobs by-core and not by-node, since part of a node should be
allocated to someone else's job.

Note that on Compute Canada clusters this launching method works without problem. On these clusters
multi-locale Chapel is provided by `chapel-ofi` (for the OmniPath interconnect on Cedar) and `chapel-ucx` (for the
InfiniBand interconnect on Graham, Béluga, Narval) modules, so -- depending on the cluster -- you will load
Chapel using one of the two lines below:

~~~
$ module load gcc chapel-ofi   # for the OmniPath interconnect on Cedar cluster
$ module load gcc chapel-ucx   # for the InfiniBand interconnect on Graham, Béluga, Narval clusters
~~~
{: .bash}

<!-- We cannot configure the same single launcher for both. Therefore, we launch -->

We can also launch multi-locale Chapel codes using the real executable `mybinary_real`. For example, for an
interactive job you would type:

~~~
$ salloc --time=0:30:0 --nodes=4 --cpus-per-task=3 --mem-per-cpu=1000 --account=def-guest
$ chpl --fast mycode.chpl -o mybinary
$ srun ./mybinary_real -nl 4   # will run on four locales with max 3 cores per locale
~~~
{: .bash}

Production jobs would be launched with `sbatch` command and a Slurm launch
script as usual.

For the rest of this class we assume that you have a working multi-locale
Chapel environment, whether provided by a Docker container or by multi-locale
Chapel on a physical HPC cluster. We will run all examples on four nodes with
three cores per node.

# Intro to multi-locale code

Let us test our multi-locale Chapel environment by launching the following
code:

~~~
writeln(Locales);
~~~
{: .source}

This code will print the built-in global array `Locales`. Running it on four
locales will produce

~~~
LOCALE0 LOCALE1 LOCALE2 LOCALE3
~~~
{: .output}

We want to run some code on each locale (node). For that, we can cycle through
locales:

~~~
for loc in Locales do   // this is still a serial program
  on loc do             // run the next line on locale `loc`
    writeln("this locale is named ", here.name);
~~~
{: .output}

This will produce

~~~
this locale is named cdr544
this locale is named cdr552
this locale is named cdr556
this locale is named cdr692
~~~
{: .output}

Here the built-in variable class `here` refers to the locale on which the code
is running, and `here.name` is its hostname. We started a serial `for` loop
cycling through all locales, and on each locale we printed its name, i.e., the
hostname of each node. This program ran in serial starting a task on each
locale only after completing the same task on the previous locale. Note the
order in which locales were listed.

To run this code in parallel, starting four simultaneous tasks, one per locale,
we simply need to replace `for` with `forall`:

~~~
forall loc in Locales do   // now this is a parallel loop
  on loc do
    writeln("this locale is named ", here.name);
~~~
{: .source}

This starts four tasks in parallel, and the order in which the print statement
is executed depends on the runtime conditions and can change from run to run:

~~~
this locale is named cdr544
this locale is named cdr692
this locale is named cdr556
this locale is named cdr552
~~~
{: .output}

We can print few other attributes of each locale. Here it is actually useful to
revert to the serial loop `for` so that the print statements appear in order:

~~~
use Memory;
for loc in Locales do
  on loc {
    writeln("locale #", here.id, "...");
    writeln("  ...is named: ", here.name);
    writeln("  ...has ", here.numPUs(), " processor cores");
    writeln("  ...has ", here.physicalMemory(unit=MemUnits.GB, retType=real), " GB of memory");
    writeln("  ...has ", here.maxTaskPar, " maximum parallelism");
  }
~~~
{: .source}

~~~
locale #0...
  ...is named: cdr544
  ...has 3 processor cores
  ...has 125.804 GB of memory
  ...has 3 maximum parallelism
locale #1...
  ...is named: cdr552
  ...has 3 processor cores
  ...has 125.804 GB of memory
  ...has 3 maximum parallelism
locale #2...
  ...is named: cdr556
  ...has 3 processor cores
  ...has 125.804 GB of memory
  ...has 3 maximum parallelism
locale #3...
  ...is named: cdr692
  ...has 3 processor cores
  ...has 125.804 GB of memory
  ...has 3 maximum parallelism
~~~
{: .output}

Note that while Chapel correctly determines the number of cores available
inside our job on each node, and the maximum parallelism (which is the same as
the number of cores available!), it lists the total physical memory on each
node available to all running jobs which is not the same as the total memory
per node allocated to our job.
