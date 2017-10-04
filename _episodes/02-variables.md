---
title: "Basic syntax and variables"
teaching: 60
exercises: 30
questions:
- "How do I write basic Chapel code?"
objectives:
- "First objective."
keypoints:
- "First key point."
---

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
