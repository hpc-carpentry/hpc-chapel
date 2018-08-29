---
title: "Domains and data parallelism"
teaching: 120
exercises: 60
questions:
- "How do I store and manipulate data across multiple locales?"
objectives:
- "First objective."
keypoints:
- "Domains are multi-dimensional sets of integer indices."
- "A domain can be defined on a single locale or distributed across many locales."
- "There are many predefined distribution method: block, cyclic, etc."
- "Arrays are defined on top of domains and inherit their distribution model."
---

# Domains and single-locale data parallelism

We start this section by recalling the definition of a range in Chapel. A range is a 1D set of integer
indices that can be bounded or infinite:

~~~
var oneToTen: range = 1..10; // 1, 2, 3, ..., 10
var a = 1234, b = 5678;
var aToB: range = a..b; // using variables
var twoToTenByTwo: range(stridable=true) = 2..10 by 2; // 2, 4, 6, 8, 10
var oneToInf = 1.. ; // unbounded range
~~~
{:.source}

On the other hand, domains are multi-dimensional (including 1D) sets of integer indices that are always
bounded. To stress the difference between domain ranges and domains, domain definitions always enclose
their indices in curly brackets. Ranges can be used to define a specific dimension of a domain:

~~~
var domain1to10: domain(1) = {1..10};        // 1D domain from 1 to 10 defined using the range 1..10
var twoDimensions: domain(2) = {-2..2,0..2}; // 2D domain over a product of two ranges
var thirdDim: range = 1..16; // a range
var threeDims: domain(3) = {thirdDim, 1..10, 5..10}; // 3D domain over a product of three ranges
for idx in twoDimensions do // cycle through all points in a 2D domain
  write(idx, ", ");
writeln();
for (x,y) in twoDimensions { // can also cycle using explicit tuples (x,y)
  write("(", x, ", ", y, ")", ", ");
}
~~~
{:.source}

Let us define an n^2 domain called `mesh`. It is defined by the single task in our code and is therefore
defined in memory on the same node (locale 0) where this task is running. For each of n^2 mesh points,
let us print out

(1) m.locale.id = the ID of the locale holding that mesh point (should be 0)  
(2) here.id = the ID of the locale on which the code is running (should be 0)  
(3) here.maxTaskPar = the number of cores (max parallelism with 1 task/core) (should be 3)  

**Note**: We already saw some of these variables/functions: numLocales, Locales, here.id, here.name,
here.numPUs(), here.physicalMemory(), here.maxTaskPar.

~~~
config const n = 8;
const mesh: domain(2) = {1..n, 1..n};  // a 2D domain defined in shared memory on a single locale
forall m in mesh { // go in parallel through all n^2 mesh points
  writeln((m, m.locale.id, here.id, here.maxTaskPar));
}
~~~
{:.source}

~~~
((7, 1), 0, 0, 3)
((1, 1), 0, 0, 3)
((7, 2), 0, 0, 3)
((1, 2), 0, 0, 3)
...
((6, 6), 0, 0, 3)
((6, 7), 0, 0, 3)
((6, 8), 0, 0, 3)
~~~
{:.output}

Now we are going to learn two very important properties of Chapel domains. First, domains can be used to
define arrays of variables of any type on top of them. For example, let us define an n^2 array of real
numbers on top of `mesh`:

~~~
config const n = 8;
const mesh: domain(2) = {1..n, 1..n};  // a 2D domain defined in shared memory on a single locale
var T: [mesh] real; // a 2D array of reals defined in shared memory on a single locale (mapped onto this domain)
forall t in T { // go in parallel through all n^2 elements of T
  writeln((t, t.locale.id));
}
~~~
{:.source}

~~~
(0.0, 0)
(0.0, 0)
(0.0, 0)
(0.0, 0)
...
(0.0, 0)
(0.0, 0)
(0.0, 0)
~~~
{:.output}

By default, all n^2 array elements are set to zero, and all of them are defined on the same locale as the
underlying mesh. We can also cycle through all indices of T by accessing its domain:

~~~
forall idx in T.domain {
  writeln(idx, ' ', T(idx));   // idx is a tuple (i,j); also print the corresponding array element
}
~~~
{:.source}

~~~
(7, 1) 0.0
(1, 1) 0.0
(7, 2) 0.0
(1, 2) 0.0
...
(6, 6) 0.0
(6, 7) 0.0
(6, 8) 0.0
~~~
{:.output}

Since we use a paralell `forall` loop, the print statements appear in a random runtime order.

We can also define multiple arrays on the same domain:

~~~
const grid = {1..100}; // 1D domain
const alpha = 5; // some number
var A, B, C: [grid] real; // local real-type arrays on this 1D domain
B = 2; C = 3;
forall (a,b,c) in zip(A,B,C) do // parallel loop
  a = b + alpha*c;   // simple example of data parallelism on a single locale
writeln(A);
~~~
{:.source}

The second important property of Chapel domains is that they can span multiple locales (nodes).

## Distributed domains

Domains are fundamental Chapel concept for distributed-memory data parallelism. 

Let us now define an n^2 distributed (over several locales) domain `distributedMesh` mapped to locales in
blocks. On top of this domain we define a 2D block-distributed array A of strings mapped to locales in
exactly the same pattern as the underlying domain. Let us print out

(1) a.locale.id = the ID of the locale holding the element a of A  
(2) here.name = the name of the locale on which the code is running  
(3) here.maxTaskPar = the number of cores on the locale on which the code is running  

Instead of printing these values to the screen, we will store this output inside each element of A as a string:  
a = "%i".format(int) + string + int  
is a shortcut for  
a = "%i".format(int) + string + "%i".format(int)  

~~~
use BlockDist; // use standard block distribution module to partition the domain into blocks
config const n = 8;
const mesh: domain(2) = {1..n, 1..n};
const distributedMesh: domain(2) dmapped Block(boundingBox=mesh) = mesh;
var A: [distributedMesh] string; // block-distributed array mapped to locales
forall a in A { // go in parallel through all n^2 elements in A
  // assign each array element on the locale that stores that index/element
  a = "%i".format(a.locale.id) + '-' + here.name + '-' + here.maxTaskPar + '  ';
}
writeln(A);
~~~~
{:.source}

The syntax `boundingBox=mesh` tells the compiler that the outer edge of our decomposition coincides
exactly with the outer edge of our domain. Alternatively, the outer decomposition layer could include an
additional perimeter of *ghost points* if we specify

~~~
const mesh: domain(2) = {1..n, 1..n};
const largerMesh: domain(2) dmapped Block(boundingBox=mesh) = {0..n+1,0..n+1};
~~~~
{:.source}

but let us not worry about this for now.

Running our code on four locales with three cores per locale produces the following output:

~~~
0-cdr544-3   0-cdr544-3   0-cdr544-3   0-cdr544-3   1-cdr552-3   1-cdr552-3   1-cdr552-3   1-cdr552-3  
0-cdr544-3   0-cdr544-3   0-cdr544-3   0-cdr544-3   1-cdr552-3   1-cdr552-3   1-cdr552-3   1-cdr552-3  
0-cdr544-3   0-cdr544-3   0-cdr544-3   0-cdr544-3   1-cdr552-3   1-cdr552-3   1-cdr552-3   1-cdr552-3  
0-cdr544-3   0-cdr544-3   0-cdr544-3   0-cdr544-3   1-cdr552-3   1-cdr552-3   1-cdr552-3   1-cdr552-3  
2-cdr556-3   2-cdr556-3   2-cdr556-3   2-cdr556-3   3-cdr692-3   3-cdr692-3   3-cdr692-3   3-cdr692-3  
2-cdr556-3   2-cdr556-3   2-cdr556-3   2-cdr556-3   3-cdr692-3   3-cdr692-3   3-cdr692-3   3-cdr692-3  
2-cdr556-3   2-cdr556-3   2-cdr556-3   2-cdr556-3   3-cdr692-3   3-cdr692-3   3-cdr692-3   3-cdr692-3  
2-cdr556-3   2-cdr556-3   2-cdr556-3   2-cdr556-3   3-cdr692-3   3-cdr692-3   3-cdr692-3   3-cdr692-3  
~~~
{:.output}

As we see, the domain `distributedMesh` (along with the string array `A` on top of it) was decomposed
into 2x2 blocks stored on the four nodes, respectively. Equally important, for each element `a` of the
array, the line of code filling in that element ran on the same locale where that element was stored. In
other words, this code ran in parallel (`forall` loop) on four nodes, using up to three cores on each
node to fill in the corresponding array elements. Once the parallel loop is finished, the `writeln`
command runs on locale 0 gathering remote elements from other locales and printing them to standard
output.

Now we can print the range of indices for each sub-domain by adding the following to our code:

~~~
for loc in Locales {
  on loc {
    writeln(A.localSubdomain());
  }
}
~~~
{:.source}

On 4 locales we should get:

~~~
{1..4, 1..4}  
{1..4, 5..8}  
{5..8, 1..4}  
{5..8, 5..8}  
~~~
{:.output}

Let us count the number of threads by adding the following to our code:

~~~
var counter = 0;
forall a in A with (+ reduce counter) { // go in parallel through all n^2 elements
  counter = 1;
}
writeln("actual number of threads = ", counter);
~~~
{:.source}

If `n=8` in our code is sufficiently large, there are enough array elements per node (8*8/4 = 16 in our
case) to fully utilize all three available cores on each node, so our output should be

~~~
actual number of threads = 12
~~~
{:.output}

Try reducing the array size `n` to see if that changes the output (fewer tasks per locale), e.g., setting
n=3. Also try increasing the array size to n=20 and study the output. Does the output make sense?

So far we looked at the block distribution `BlockDist`. It will distribute a 2D domain among nodes either
using 1D or 2D decomposition (in our example it was 2D decomposition 2x2), depending on the domain size
and the number of nodes.

Let us take a look at another standard module for domain partitioning onto locales, called
CyclicDist. For each element of the array we will print out again

(1) a.locale.id = the ID of the locale holding the element a of A  
(2) here.name = the name of the locale on which the code is running  
(3) here.maxTaskPar = the number of cores on the locale on which the code is running  

~~~
use CyclicDist; // elements are sent to locales in a round-robin pattern
config const n = 8;
const mesh: domain(2) = {1..n, 1..n};  // a 2D domain defined in shared memory on a single locale
const m2: domain(2) dmapped Cyclic(startIdx=mesh.low) = mesh; // mesh.low is the first index (1,1)
var A2: [m2] string;
forall a in A2 {
  a = "%i".format(a.locale.id) + '-' + here.name + '-' + here.maxTaskPar + '  ';
}
writeln(A2);
~~~
{:.source}

~~~
0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3  
2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3  
0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3  
2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3  
0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3  
2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3  
0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3   0-cdr544-3   1-cdr552-3  
2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3   2-cdr556-3   3-cdr692-3  
~~~
{:.output}

As the name `CyclicDist` suggests, the domain was mapped to locales in a cyclic, round-robin pattern. We
can also print the range of indices for each sub-domain by adding the following to our code:

~~~
for loc in Locales {
  on loc {
    writeln(A2.localSubdomain());
  }
}
~~~
{:.source}

~~~
{1..7 by 2, 1..7 by 2}  
{1..7 by 2, 2..8 by 2}  
{2..8 by 2, 1..7 by 2}  
{2..8 by 2, 2..8 by 2}  
~~~
{:.output}

In addition to BlockDist and CyclicDist, Chapel has several other predefined distributions: BlockCycDist,
ReplicatedDist, DimensionalDist2D, ReplicatedDim, BlockCycDim -- for details please see
http://chapel.cray.com/docs/1.12/modules/distributions.html.

## Diffusion solver on distributed domains

Now let us use distributed domains to write a parallel version of our original diffusion solver code:

~~~
use BlockDist;
config const n = 8;
const mesh: domain(2) = {1..n, 1..n};  // local 2D n^2 domain
~~~
{:.source}

We will add a larger (n+2)^2 block-distributed domain `largerMesh` with a layer of *ghost points* on
*perimeter locales*, and define a temperature array T on top of it, by adding the following to our code:

~~~
const largerMesh: domain(2) dmapped Block(boundingBox=mesh) = {0..n+1, 0..n+1};
var T: [largerMesh] real; // a block-distributed array of temperatures
forall (i,j) in T.domain[1..n,1..n] {
  var x = ((i:real)-0.5)/(n:real); // x, y are local to each task
  var y = ((j:real)-0.5)/(n:real);
  T[i,j] = exp(-((x-0.5)**2 + (y-0.5)**2) / 0.01); // narrow gaussian peak
}
writeln(T);
~~~
{:.source}

Here we initialized an initial Gaussian temperature peak in the middle of the mesh. As we evolve our
solution in time, this peak should diffuse slowly over the rest of the domain.

> ## Question
> Why do we have  
> forall (i,j) in T.domain[1..n,1..n] {  
> and not  
> forall (i,j) in mesh
>> ## Answer
>> The first one will run on multiple locales in parallel, whereas the
>> second will run in parallel via multiple threads on locale 0 only, since
>> "mesh" is defined on locale 0.
>> {:.source}

The code above will print the initial temperature distribution:

~~~
0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0  
0.0 2.36954e-17 2.79367e-13 1.44716e-10 3.29371e-09 3.29371e-09 1.44716e-10 2.79367e-13 2.36954e-17 0.0  
0.0 2.79367e-13 3.29371e-09 1.70619e-06 3.88326e-05 3.88326e-05 1.70619e-06 3.29371e-09 2.79367e-13 0.0  
0.0 1.44716e-10 1.70619e-06 0.000883826 0.0201158 0.0201158 0.000883826 1.70619e-06 1.44716e-10 0.0  
0.0 3.29371e-09 3.88326e-05 0.0201158 0.457833 0.457833 0.0201158 3.88326e-05 3.29371e-09 0.0  
0.0 3.29371e-09 3.88326e-05 0.0201158 0.457833 0.457833 0.0201158 3.88326e-05 3.29371e-09 0.0  
0.0 1.44716e-10 1.70619e-06 0.000883826 0.0201158 0.0201158 0.000883826 1.70619e-06 1.44716e-10 0.0  
0.0 2.79367e-13 3.29371e-09 1.70619e-06 3.88326e-05 3.88326e-05 1.70619e-06 3.29371e-09 2.79367e-13 0.0  
0.0 2.36954e-17 2.79367e-13 1.44716e-10 3.29371e-09 3.29371e-09 1.44716e-10 2.79367e-13 2.36954e-17 0.0  
0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0  
~~~
{:.output}

Let us define an array of strings `nodeID` with the same distribution over locales as T, by adding the
following to our code:

~~~
var nodeID: [largerMesh] string;
forall m in nodeID do
  m = "%i".format(here.id);
writeln(nodeID);
~~~
{:.source}

The outer perimeter in the partition below are the *ghost points*:

~~~
0 0 0 0 0 1 1 1 1 1  
0 0 0 0 0 1 1 1 1 1  
0 0 0 0 0 1 1 1 1 1  
0 0 0 0 0 1 1 1 1 1  
0 0 0 0 0 1 1 1 1 1  
2 2 2 2 2 3 3 3 3 3  
2 2 2 2 2 3 3 3 3 3  
2 2 2 2 2 3 3 3 3 3  
2 2 2 2 2 3 3 3 3 3  
2 2 2 2 2 3 3 3 3 3  
~~~
{:.output}

> ## Exercise 3
> In addition to here.id, also print the ID of the locale holding that value. Is it the same or different
> from here.id?
>> ## Solution
>> Something along the lines:
>>   m = "%i".format(here.id) + '-' + m.locale.id

Now we implement the parallel solver, by adding the following to our code (*contains a mistake on
purpose!*):

~~~
var Tnew: [largerMesh] real;
for step in 1..5 { // time-stepping
  forall (i,j) in mesh do
    Tnew[i,j] = (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1]) / 4;
  T[mesh] = Tnew[mesh]; // uses parallel forall underneath
}
~~~
{:.source}

> ## Exercise 4
> Can anyone see a mistake in the last code?
>> ## Solution
>> It should be  
>>   forall (i,j) in Tnew.domain[1..n,1..n] do  
>> instead of  
>>   forall (i,j) in mesh do  
>> as the last one will likely run in parallel via threads only on locale 0,
>> whereas the former will run on multiple locales in parallel.

Here is the final version of the entire code:

~~~
use BlockDist;
config const n = 8;
const mesh: domain(2) = {1..n,1..n};
const largerMesh: domain(2) dmapped Block(boundingBox=mesh) = {0..n+1,0..n+1};
var T, Tnew: [largerMesh] real;
forall (i,j) in T.domain[1..n,1..n] {
  var x = ((i:real)-0.5)/(n:real);
  var y = ((j:real)-0.5)/(n:real);
  T[i,j] = exp(-((x-0.5)**2 + (y-0.5)**2) / 0.01);
}
for step in 1..5 {
  forall (i,j) in Tnew.domain[1..n,1..n] {
    Tnew[i,j] = (T[i-1,j]+T[i+1,j]+T[i,j-1]+T[i,j+1])/4.0;
  }
  T = Tnew;
  writeln((step,T[n/2,n/2],T[1,1]));
}
~~~
{:.source}

This is the entire parallel solver! Note that we implemented an open boundary: T on *ghost points* is
always 0. Let us add some printout and also compute the total energy on the mesh, by adding the following
to our code:

~~~
  writeln((step, T[n/2,n/2], T[2,2]));
  var total: real = 0;
  forall (i,j) in mesh with (+ reduce total) do
    total += T[i,j];
  writeln("total = ", total);
~~~
{:.source}

Notice how the total energy decreases in time with the open BCs, as the energy is leaving the system.

> ## Exercise 5
> Write a code to print how the finite-difference stencil [i,j], [i-1,j], [i+1,j], [i,j-1], [i,j+1] is
> distributed among nodes, and compare that to the ID of the node where T[i,i] is computed.
>> ## Solution
>> Here is one possible solution examining the locality of the finite-difference stencil:
>> ~~~
>> var nodeID: [largerMesh] string = 'empty';
>> forall (i,j) in nodeID.domain[1..n,1..n] do
>>   nodeID[i,j] = "%i".format(here.id) + nodeID[i,j].locale.id + nodeID[i-1,j].locale.id +
>>     nodeID[i+1,j].locale.id + nodeID[i,j-1].locale.id + nodeID[i,j+1].locale.id + '  ';
>> writeln(nodeID);
>> ~~~

This produced the following output clearly showing the *ghost points* and the stencil distribution for
each mesh point:

~~~
empty empty empty empty empty empty empty empty empty empty  
empty 000000   000000   000000   000001   111101   111111   111111   111111   empty  
empty 000000   000000   000000   000001   111101   111111   111111   111111   empty  
empty 000000   000000   000000   000001   111101   111111   111111   111111   empty  
empty 000200   000200   000200   000201   111301   111311   111311   111311   empty  
empty 220222   220222   220222   220223   331323   331333   331333   331333   empty  
empty 222222   222222   222222   222223   333323   333333   333333   333333   empty  
empty 222222   222222   222222   222223   333323   333333   333333   333333   empty  
empty 222222   222222   222222   222223   333323   333333   333333   333333   empty  
empty empty empty empty empty empty empty empty empty empty  
~~~
{:.output}

Note that T[i,j] is always computed on the same node where that element is stored, which makes sense.

## Periodic boundary conditions

Now let us modify the previous parallel solver to include periodic BCs. At the beginning of each time
step we need to set elements on the *ghost points* to their respective values on the *opposite ends*, by
adding the following to our code:

~~~
  T[0,1..n] = T[n,1..n]; // periodic boundaries on all four sides; these will run via parallel forall
  T[n+1,1..n] = T[1,1..n];
  T[1..n,0] = T[1..n,n];
  T[1..n,n+1] = T[1..n,1];
~~~
{:.source}

Now total energy should be conserved, as nothing leaves the domain.

# I/O

Let us write the final solution to disk. There are several caveats:

* works only with ASCII
* Chapel can also write binary data but nothing can read it (checked: not the endians problem!)
* would love to write NetCDF and HDF5, probably can do this by calling C/C++ functions from Chapel

We'll add the following to our code to write ASCII:

~~~
var myFile = open("output.dat", iomode.cw); // open the file for writing
var myWritingChannel = myFile.writer(); // create a writing channel starting at file offset 0
myWritingChannel.write(T); // write the array
myWritingChannel.close(); // close the channel
~~~
{:.source}

Run the code and check the file *output.dat*: it should contain the array T after 5 steps in ASCII.

# Ideas for future topics or homework

* binary I/O
* write/read NetCDF from Chapel by calling a C/C++ function
* take a simple non-linear problem, linearize it, implement a parallel multi-locale linear solver
  entirely in Chapel

