Welcome to Emcee project, an ultimate solution for running iOS tests in parallel locally and across many Macs. 

Emcee allows you to run UI tests on many physical machines, distributing the work and getting the results of the test run faster.

It manages the order of test execution, the simulators, and maintains the queue with tests that being run. 

It can generate the Junit and trace reports to make you see how the test run behaved on different machines.

# Using Emcee

Up to date documentation is available on [Wiki](https://github.com/avito-tech/Emcee/wiki).

# Publications

- [Emcee  —  Open Source Tool for iOS UI Testing Infrastructure @ Medium](https://link.medium.com/aHywQuI6jU)
- [NSSpain 2018: UI Testing Infrastructure in Avito @ Vimeo](https://vimeo.com/292738016)

# Getting Around the Code

Emcee uses Swift Package Manager for building, testing and exposing the Swift packages.

To start exploring code open `Package.swift` in Xcode 11 or execute `make open` to generate and open Xcode project.

# Contributing

We are happy to accept your pull requests. If something does not work for you, please let us know by submitting an issue. Reads the docs and suggest improvements to them as well!

General commands that help you with a development workflow:

- Generating an Xcode project: `make open`
- Building the binary: `make build`
- Running unit tests: `make test`

# Dependencies

## libssh2

`brew install libssh2`

## FBSimulatorControl

Emcee depends heavily on [FBSimulatorControl](https://github.com/beefon/FBSimulatorControl) library, which is a set of APIs to work with iOS Simulator and iOS devices. 

We have a [fork](https://github.com/beefon/FBSimulatorControl) which contains some extensions, so please check it out and 
provide [the binaries](https://github.com/beefon/FBSimulatorControl/releases/tag/avito0.0.8) of the fbxctest and fbsimctl to the Emcee. 
