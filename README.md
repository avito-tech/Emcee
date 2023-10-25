![Emcee Banner](https://raw.github.com/avito-tech/Emcee/master/Resources/banner.png)

Welcome to Emcee project, an ultimate solution for running Android and iOS tests in parallel across many servers, let it be bare metal or containerised. 

Emcee allows you to run unit, integration and UI tests in smaller chunks, distributing the load and getting the results of the test run faster. Shared queue manages the order of test execution. Emcee workers execute tests and maintain lifecycle of their simulators/emulators automatically. Emcee can generate various test reports like Junit, Allure, XCResult. Trace reports will help you to see how the test run behaves on different machines.

# Features

- Rich test plans using simple JSON file format

- Automatic simulator/emulator lifecycle management

- Per-test timeouts, simulator settings, environment variables

- Single test queue to run tests from multiple parallel pull requests

- Prioritized jobs and job groups for different kinds of test runs

- Load balancing of worker machines to achieve optimal parallelization performance

- On-the-go maintenance of the workers

- Integration into existing test management systems via plugins

- Easy to use command line interface

- Rich test discovery mechanism

- Advanced analytic events and logs sent by workers and queue

## Emcee setup

In the process of getting Emcee deployed and functional, you will encounter the following terms.
* `queue` - An Emcee queue accepts testing requests from clients, split tests into buckets for distributed execution, controls load and which tasks get placed on which workers. Queue is also in charge of detecting stuck buckets and recovering in case of failures.
* `worker` - An Emcee worker is responsible for running the tests assigned to it. It also registers itself with the queue and watches for any work to be assigned.
* `client` - A client acts as an interface (cli or gradle plugin) to the queue with ability to poll tests run status.

## Testing workflow

A typical testing workflow involves several steps and begins outside of Emcee.

![Workflow](https://raw.github.com/avito-tech/Emcee/master/Resources/workers_animation.gif)

The prerequisite for any tests running on Emcee is having an input artifacts. Emcee supports diffrent input types: xctest, target and runner application bundles, xctestrun (derivative from test plan) for iOS and application, testApplication apk for Android.
Emcee does not create these test inputs. Normally you employ CI tools like GitHub Actions, CircleCI to build a project and then upload build artifacts to a storage accessible by Emcee workers. Or local build can be used to create such aritifacts and Emcee client will serve them when it schedules a test run.

Get started with local building and testing iOS apps on Emcee with our [sample projects](https://github.com/avito-tech/Emcee/wiki/iOS).
Deploy Emcee queue and workers to run your Android tests using our [guide](https://github.com/avito-tech/Emcee/wiki/Android-documentation).

## Advanced Emcee configuration

Complete documentation is available in our [Wiki](https://github.com/avito-tech/Emcee/wiki).

`runTests` command allows you to get Emcee up and running quickly; however, it doesn't allow for a lot of configuration. On the other hand, `runTestsOnRemoteQueue` command allows for fine-grained control of how your tests execute. To get started with `runTestsOnRemoteQueue` check out the [Queue Server Configuration](https://github.com/avito-tech/Emcee/wiki/Queue-Server-Configuration) and [Test Arg File](https://github.com/avito-tech/Emcee/wiki/Test-Arg-File) wiki pages.

# Publications

- [Emcee  —  Open Source Tool for iOS UI Testing Infrastructure @ Medium](https://link.medium.com/aHywQuI6jU)
- [NSSpain 2018: UI Testing Infrastructure in Avito @ Vimeo](https://vimeo.com/292738016)

# Getting Around the Code

Emcee uses Swift Package Manager for building, testing and exposing the Swift packages.

To start exploring code open `Package.swift` or execute `make open` to generate and open Xcode project.

# Contributing

We are happy to accept your pull requests. If something does not work for you, please let us know by submitting an issue. Read the docs and suggest improvements to them as well!

General commands that help you with a development workflow:

- To open a package in Xcode: `make open`
- To generate `Package.swift`: `make package`
- To build the binary into `.build/debug/Emcee`: `make build`
- To run unit tests: `make test`

`Package.swift` file is generated automatically. You must update it before submitting a pull request (run `make package`). CI checks will fail if you forget to do so.