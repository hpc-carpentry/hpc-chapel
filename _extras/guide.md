---
layout: page
title: "Instructor Notes"
permalink: /guide/
---

This Chapel section is a full-day class. We expect it to be taught by a staff member from an HPC centre, and we assume that multi-locale Chapel has been already installed on the system that will be used for the hands-on exercises. For this reason, here we do not provide instructions for installing Chapel, as it can be done in several different ways, with the details depending on the cluster's scheduler and the physical interconnect, and it would be best to leave Chapel installation to knowledgeable HPC staff.

Having said that, there are also ways to run Chapel entirely on attendees' laptops. This option is less than ideal, as there are some drawbacks to not having multi-locale Chapel running on actual physical compute nodes on a cluster. Here we mention the possible installation modes if an HPC cluster is not available:

(1) You can install single-locale Chapel on a laptop and run it on multiple cores. Obviously, you will not be able to do data decomposition and parallelism across multiple nodes.

(2) You can run multi-locale Chapel inside a docker container (`docker pull chapel/chapel-gasnet`). This will imitate an HPC cluster (without the scheduler) on which you'll be able to do data parallelism. However, since you'll be running on the same set of physical laptop cores, you will not get any acceleration from running multi-locale Chapel. This is the probably the best option for testing all Chapel features without access to an actual cluster.
