---
title: Setup
---

We highly recommend running Chapel on an HPC cluster. Alternatively, you can run Chapel on your computer, but
don't expect a multi-node speedup since you have only one node.

<!-- ## Data Sets -->

<!-- <\!-- -->
<!-- FIXME: place any data you want learners to use in `episodes/data` and then use -->
<!--        a relative link ( [data zip file](data/lesson-data.zip) ) to provide a -->
<!--        link to it, replacing the example.com link. -->
<!-- -\-> -->
<!-- Download the [data zip file](https://example.com/FIXME) and unzip it to your Desktop -->

## Software Setup

::::::::::::::::::::::::::::::::::::::: discussion

### Details

This section describes installing Chapel on your own computer. Before proceeding, please double-check that
your workshop instructors do not already provide Chapel on an HPC cluster.

<!-- Setup for different systems can be presented in dropdown menus via a `spoiler` -->
<!-- tag. They will join to this discussion block, so you can give a general overview -->
<!-- of the software used in this lesson here and fill out the individual operating -->
<!-- systems (and potentially add more, e.g. online setup) in the solutions blocks. -->

:::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::: spoiler

### Windows

Go to the website https://docs.docker.com/docker-for-windows/install/ and download the Docker Desktop
installation file. Double-click on the `Docker_Desktop_Installer.exe` to run the installer. During the
installation process, enable Hyper-V Windows Feature on the Configuration page, and wait for the installation
to complete. At this point you might need to restart your computer.

Eventually you want to run https://hub.docker.com/r/chapel/chapel Docker image.

::::::::::::::::::::::::

:::::::::::::::: spoiler

### MacOS

The quickest way to get started with Chapel on MacOS is to install it via Homebrew. If you don't have Homebrew
installed (skip this step if you do), open Terminal.app and type

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Next, proceed to installing Chapel:

```bash
brew update
brew install chapel
```

<!-- Compile and run a test program: -->

<!-- ```bash -->
<!-- chpl $(brew --cellar)/chapel/<chapel-version>/libexec/examples/hello.chpl -->
<!-- ./hello -->
<!-- ``` -->

::::::::::::::::::::::::


:::::::::::::::: spoiler

### Linux

At https://github.com/chapel-lang/chapel/releases scroll to the first "Assets" section (you might need to
click on "Show all assets") and pick the latest precompiled Chapel package for your Linux distribution. For
example, with Ubuntu 22.04 you can do:

```bash
wget https://github.com/chapel-lang/chapel/releases/download/2.0.0/chapel-2.1.0-1.ubuntu22.amd64.deb
sudo apt install ./chapel-2.1.0-1.ubuntu22.amd64.deb
```

::::::::::::::::::::::::
