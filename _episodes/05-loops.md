---
title: "Getting started with loops"
teaching: 60
exercises: 30
questions:
- "How do I get run the same piece of code repeatedly?"
objectives:
- "First objective."
keypoints:
- "Use `for` statement to organize a loop."
---

To compute the current temperature of an element of `temp`, we need to add all the surrounding elements in `past_temp`, and divide the result by 4. And, esentially, we need to repeat this process for all the elements of `temp`, or, in other words, we need to *iterate* over the elements of `temp`. When it comes to iterate over a given number of elements, the **_for-loop_** is what we want to use. The for-loop has the following general syntax: 

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
past_temp=temp;
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

> ## Exercise 1
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
> Now let's have some more interesting boundary conditions. Suppose that the plate is heated by a source of 80 degrees located at the bottom right corner, and that the temperature on the rest of the border decreases linearly as one gets farther form the corner (see the image below). Utilize for loops to setup the described boundary conditions. Compile and run your code to see how the temperature is changing now. 
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
>>     tt=abs(temp[i,j]-past_temp[i,j]);
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
