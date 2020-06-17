Welcome to Emcee project, an ultimate solution for running iOS tests in parallel locally and across many Macs. 

Emcee allows you to run UI tests on many physical machines, distributing the work and getting the results of the test run faster. Shared queue manages the order of test execution. Emcee workers execute tests and maintain lifecycle of their simulators automatically. Emcee can generate the Junit and trace reports to make you see how the test run behaved on different machines.

# Using Emcee

Up to date documentation is available on [Wiki](https://github.com/avito-tech/Emcee/wiki).

# Features

- Rich test plans using simple JSON file format

- Automatic simulator lifecycle management

- Per-test timeouts, simulator settings, environment variables

- Single test queue to run tests from multiple parallel pull requests

- Prioritized jobs and job groups for different kinds of test runs

- Load balancing of worker machines to achieve optimal parallelization performance

- On-the-go maintenance of the workers

- Integration into existing test management systems via plugins

- Easy to use command line interface

- Rich test discovery mechanism

- Swift Package for using and extending Emcee the way you want

# Publications

- [Emcee  —  Open Source Tool for iOS UI Testing Infrastructure @ Medium](https://link.medium.com/aHywQuI6jU)
- [NSSpain 2018: UI Testing Infrastructure in Avito @ Vimeo](https://vimeo.com/292738016)

# Getting Around the Code

Emcee uses Swift Package Manager for building, testing and exposing the Swift packages.

To start exploring code open `Package.swift` in Xcode 11 or execute `make open` to generate and open Xcode project.

# Contributing

We are happy to accept your pull requests. If something does not work for you, please let us know by submitting an issue. Read the docs and suggest improvements to them as well!

General commands that help you with a development workflow:

- Generating an Xcode project: `make open`
- Generating `Package.swift` based on template and `import` statements in source code: `make gen`
- Building the binary at `.build/debug/Emcee`: `make build`
- Running unit tests: `make test`

Since `Package.swift` file is generated automatically, you must update it before submitting a pull request. CI checks will fail if you forget to do so.

# Dependencies

## libssh2

`brew install libssh2`
