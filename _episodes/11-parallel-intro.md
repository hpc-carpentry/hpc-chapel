---
title: "Intro to parallel computing"
teaching: 60
exercises: 30
questions:
- "How does parallel processing work?"
objectives:
- "First objective."
keypoints:
- "Concurrency and locality are orthogonal concepts in Chapel: where the tasks are running may not be indicative of when they run, and you can control both in Chapel."
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
