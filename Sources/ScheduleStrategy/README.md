#  About Schedule Strategies

Schedule strategy defines the way how tests are executed, particularly, in what order they are executed.

There are various techniques how to achieve a better distribution of tests across the available destinations.

Note: when we say a destination, we mean a thing that can run tests. When you are in local test run context, the destination is a simulator.
When we are in a distributed test run context, the destination is a machine. In this case, we may say that each machine has its own set of 
destinations - simulators.

The problem is to make sure all machines and their simulators are not idle throughout the destributed or local test run. Thus, we are aiming 
to achieve the best timings for the test run by making sure all destinations are busy up to the point when the whole test run finishes.

## Available schedule strategies

### Individual

This is the most primitive schedule strategy. It generates a set of `Bucket`s with a single `TestEntry` in each bucket. Thus, this allows to
have a fine-grained control of destinations load, but increases the overhead of loading `xctest` bundle and launching `XCTRunner.app`
for each test.

### Equally divided

Another quite primitive schedule strategy which splits a list of `TestEntry` into `number of destinations` buckets 
with equall number of `TestEntry` in each. This has an advantage of having the least overhead of loading `xctest` bundle, as it will be
loaded only once for each destination. Then, the actual tests from each `Bucket` will be executed sequentially, each destination will execute 
a single `Bucket`. The downside is that it is highly likely that some destination will slow down the whole test run by talking a significat time
to fiinsh its set of tests, while the most of destinations will be idle.

### Progressive 

A smarter technique that, in theory, combines the positive sides of each schedule strategy above and attempts to solve the problem when
some destinations are idle.

This strategy type will split the set of test into the `Bucket`s with variable `TestEntry` in each. The large buckets will be executed first, 
the smaller buckets will be executed last. If some destination becomes idle, it can pick next bucket to execute. 
As the size of the bucket decreases, destinations will run more and more buckets. 
While the overhead of loading `xctest` bundle increases over time, this allows to make all destinations work and not stay idle.

### An area of improvement

It is possible to weight each `TestEntry` with a corresponding duration if this is available. This will allow to have the buckets with equal
execution duration rather than with equal number of tests in them, but this is not implemented yet.

## Working with a multiple test destinations

If we need to run a set of tests on multiple test destinations (e.g. iPhone 7 and iPhone SE), the `BucketsGenerator` will generate two
series of buckets for each destination and then merge them, preserving an order (all iPhone 7 buckets first, all iPhone SE buckets next). 
This is importaint as it is expensive to switch between different kinds of simulators.
