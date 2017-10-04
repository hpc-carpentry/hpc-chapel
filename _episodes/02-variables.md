---
title: "Basic syntax and variables"
teaching: 15
exercises: 15
questions:
- "How do I write basic Chapel code?"
objectives:
- "Perform basic math in Chapel."
- "Understand Chapel's basic data types."
- "Understand how to read and fix errors."
- "Know how to define and use data stored as variables."
keypoints:
- "A comment is preceded with `//` or surrounded by `/* and `*/`"
- "All variables hold a certain type of data."
- "Using `const` instead of `var` prevents reassignment."
---

Basic math in Chapel works the same as other programming languages. 
Try compiling the following code to see how the different mathematical operators work.

```
writeln(4 + 5);
writeln(4 - 5);
writeln(4 * 5);
writeln(4 / 5);   // integer division
writeln(4.0 / 5.0); // normal division
writeln(4 ** 5);  // exponentiation
```
{: .input}

In this example, our code is called `operators.chpl`. 
You can compile it with the following commands:
```
chpl operators.chpl --fast -o operators.o
./operators.o
```
{: .bash}

You should see output that looks something like the following:

```
9
-1
20
0
0.8
1024
```
{: .output}

Code beginning with `//` is interpreted as a comment - it does not get run.
Comments are very valuable when writing code, 
because they allow us to write notes to ourselves about what each piece of code does.
You can also create block comments with `/*` and `*/`:

```
/* This is a block comment.
It can span as many lines as you want!
(like this) */
```

## Variables

Granted, we probably want to do more than basic math with Chapel.
We will need to store the results of complex operations using variables.
Variables in programming are not the same as the mathematical concept. In programming, a variable is an allocated space in the memory of the computer, where we can store information or data while executing a program. A variable has three elements: 

1. a **_name_** or label, to identify the variable 
2. a **_type_**, that indicates the kind of data that we can store in it, and
3. a **_value_**, the actual information or data stored in the variable.

When we store a value in a variable for the first time, we say that we **_initialized_** it. Further changes to the value of a variable are called **_assignments_**, in general, `x=a` means that we assign the value *a* to the variable *x*.

Variables in Chapel are declared with the `var` or `const` keywords. When a variable declared as const is initialized, its value cannot be modified anymore during the execution of the program. 

In Chapel, to declare a variable we must specify the type of the variable, or initialize it in place with some value. The common variable types in Chapel are:

* integer `int` (positive or negative whole numbers)
* floating-point number `real` (decimal values)
* boolean `bool`  (true or false)
* srting `string` (any type of text)


If a variable is declared without a type, Chapel will infer it from the given initial value.
We can use the stored variable simply by using its name anywhere in our code (called `variables.chpl`).

~~~
const test = 100;
writeln('The value of test is: ', test);
writeln(test / 4);
~~~
{: .source}
```
chpl variables.chpl -o variables.o --fast
./variables.o
```
{: .bash}
```
The value of test is: 100
25
```
{: .output}

This constant variable `test` will be created as an integer, and initialized with the value 100. 
No other values can be assigned to these variables during the execution of the program.
What happens if we try to modify a constant variable like `test`?

~~~
const test = 100;
test = 200;
writeln('The value of test is: ', test);
writeln(test / 4);
~~~
{: .source}
```
chpl variables.chpl -o variables.o
```
{: .bash}
```
variables.chpl:2: error: illegal lvalue in assignment
```
{: .error}

The compiler threw an error, and did not compile our program.
This is a feature of compiled languages - 
if there is something wrong, we will typically see an error while writing our program, 
instead of while running it.
Although we already kind of know why the error was caused 
(we tried to reassign the value of a `const` variable, which by definition cannot be changed),
lets walk through the error as an example of how to troubleshoot our programs.

* `variables.chpl:2:` indicates that the error was caused on line 2 of our `variables.chpl` file.

* `error:` indicates that the issue was an error, and blocks compilation. Sometimes the compiler will just give us warning or information, not necessarily errors. When we see something that is not an error, we should carefully read the output and consider if it necessitates changing our code. Errors must be fixed, as they will block the code from compiling.

* `illegal lvalue in assignment` indicates that the left hand side of our assignment expression (`lvalue`) was illegal. We were trying to reassign a `const` variable, which is explicitly not allowed in Chapel.

To fix this error, we can change `const` to `var` when declaring our `test` variable.
`var` indicates a variable that can be reassigned.

~~~
var test = 100;
test = 200;
writeln('The value of test is: ', test);
writeln(test / 4);
~~~
{: .source}
```
chpl variables.chpl -o variables.o
```
{: .bash}
```
The value of test is: 200
50
```
{: .output}

It worked! Now we know both how to set, use, and change a variable, 
as well as the implications of using `var` and `const`.
We also know how to read and interpret errors.

## Uninitialized variables

On the other hand, if a variable is declared without an initial value, Chapel will initialize it with a defualt value depending on the declared type (0.0 for real variables, for example). The following variables will be created as real floating point numbers equal to 0.0.

~~~
var curdif: real;	//here we will store the greatest difference in temperature from one iteration to another 
var tt: real;		//for temporary results when computing the temperatures
~~~
{: .source}

Of course, we can use both, the initial value and the type, when declaring a varible as follows:

~~~
const mindif=0.0001: real;	//smallest difference in temperature that would be accepted before stoping
const n=20: int;		//the temperature at the desired position will be printed every n interations
~~~
{: .source}

*This is not necessary, but it could help to make the code more readable.*


Let's practice defining variables and use this as the starting point of our simulation code.
In these examples, our simulation will be in the file `base_solution.chpl`.

```
const rows = 100;		        // number of rows in matrix
const cols = 100;		        // number of columns in matrix
const niter = 500;	            // number of iterations
const x = 50;		            // row number of the desired position
const y = 50;		            // column number of the desired position
var curdif: real;	            // here we will store the greatest difference in temperature from one iteration to another 
var tt: real;		            // for temporary results when computing the temperatures
const mindif = 0.0001: real;	// smallest difference in temperature that would be accepted before stoping
const n = 20: int;		        // the temperature at the desired position will be printed every n interations
```
{: .source}
