---
title: "Intro to parallel computing"
teaching: 60
exercises: 30
---

:::::::::::::::::::::::::::::::::::::: questions
- "How does parallel processing work?"
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives
- "First objective."
::::::::::::::::::::::::::::::::::::::::::::::::

The basic concept of parallel computing is simple to understand: we divide our job into tasks that can be
executed at the same time, so that we finish the job in a fraction of the time that it would have taken if the
tasks were executed one by one. Implementing parallel computations, however, is not always easy, nor
possible...

Consider the following analogy:

Suppose that we want to paint the four walls in a room. We'll call this the *problem*. We can divide our
problem into 4 different tasks: paint each of the walls. In principle, our 4 tasks are independent from each
other in the sense that we don't need to finish one to start one another. We say that we have 4 **_concurrent
tasks_**; the tasks can be executed within the same time frame.  However, this does not mean that the tasks
can be executed simultaneously or in parallel. It all depends on the amount of resources that we have for the
tasks.  If there is only one painter, this guy could work for a while in one wall, then start painting another
one, then work for a little bit on the third one, and so on. **_The tasks are being executed concurrently but
not in parallel_**. If we have two painters for the job, then more parallelism can be introduced. Four
painters could execute the tasks **_truly in parallel_**.

::::::::::::::::::::::::::::::::::::: callout

Think of the CPU cores as the painters or workers that will execute your concurrent tasks.

::::::::::::::::::::::::::::::::::::::::::::::::

Now imagine that all workers have to obtain their paint from a central dispenser located at the middle of the
room. If each worker is using a different colour, then they can work **_asynchronously_**, however, if they
use the same colour, and two of them run out of paint at the same time, then they have to **_synchronise_** to
use the dispenser: One must wait while the other is being serviced.

::::::::::::::::::::::::::::::::::::: callout

Think of the shared memory in your computer as the central dispenser for all your workers.

::::::::::::::::::::::::::::::::::::::::::::::::

Finally, imagine that we have 4 paint dispensers, one for each worker. In this scenario, each worker can
complete their task totally on their own. They don't even have to be in the same room, they could be painting
walls of different rooms in the house, in different houses in the city, and different cities in the
country. We need, however, a communication system in place. Suppose that worker A, for some reason, needs a
colour that is only available in the dispenser of worker B, they must then synchronise: worker A must request
the paint of worker B and worker B must respond by sending the required colour.

::::::::::::::::::::::::::::::::::::: callout

Think of the memory on each node of a cluster as a separate dispenser for your workers.

::::::::::::::::::::::::::::::::::::::::::::::::

A **_fine-grained_** parallel code needs lots of communication or synchronisation between tasks, in contrast
with a **_coarse-grained_** one. An **_embarrassingly parallel_** problem is one where all tasks can be
executed completely independent from each other (no communications required).

## Parallel programming in Chapel

Chapel provides high-level abstractions for parallel programming no matter the grain size of your tasks,
whether they run in a shared memory on one node or use memory distributed across multiple compute nodes,
or whether they are executed
concurrently or truly in parallel. As a programmer you can focus in the algorithm: how to divide the problem
into tasks that make sense in the context of the problem, and be sure that the high-level implementation will
run on any hardware configuration. Then you could consider the details of the specific system you are going to
use (whether it is shared or distributed, the number of cores, etc.) and tune your code/algorithm to obtain a
better performance.

::::::::::::::::::::::::::::::::::::: callout

To this effect, **_concurrency_** (the creation and execution of multiple tasks), and **_locality_** (in
which set of resources these tasks are executed) are orthogonal concepts in Chapel.

::::::::::::::::::::::::::::::::::::::::::::::::

In summary, we can have a set of several tasks; these tasks could be running:

1. concurrently by the same processor in a single compute node,
2. in parallel by several processors in a single compute node,
3. in parallel by several processors distributed in different compute nodes, or
4. serially (one by one) by several processors distributed in different compute nodes.

Similarly, each of these tasks could be using variables

1. located in the local memory on the compute node where it is running, or 
2. stored on other compute nodes.

And again, Chapel could take care of all the stuff required to run our algorithm in most of the scenarios, but
we can always add more specific detail to gain performance when targeting a particular scenario.

::::::::::::::::::::::::::::::::::::: keypoints
- "Concurrency and locality are orthogonal concepts in Chapel: where the tasks are running may not be
  indicative of when they run, and you can control both in Chapel."
::::::::::::::::::::::::::::::::::::::::::::::::
