Welcome to Emcee project, an ultimate solution for running iOS tests in parallel locally and across many Macs. 

Emcee allows you to run UI tests on many physical machines, distributing the work and getting the results of the test run faster.
It manages the order of test execution, the simulators, and maintains the queue with tests that being run. 
It can generate the Junit and trace to make you see how the test run behaved on different machines.

# Getting Started

The most easy way to run your tests is to invoke a command line tool.

You will need to have the following build artifacts around:

* .app bundle
* Runner.app bundle

You can use `xcodebuild build-for-testing` command to generate these build artifacts. 

Run `AvitoRunner runTests --help` to see the full command syntax. 

# What Can This Project Do

The CLI is split into subcommands. Currently there are 4 commands supported:

- `runTests` - actually runs the UI tests on local machine and generates a report.
- `distRunTests` - brings up the queue with tests to run, deploys the required data to the remote machines over SSH and then starts 
remote agents that run UI tests on remote machines. After runnng all tests, creates a report on local machine.
- `distWork` - starts the runner as a client to the queue server that you start using the `distRunTests` command on the remote machines.
This can be considered as a worker instance of the runner.
- `dump` - runs runtime dump. This is a feature that allows you to filter the tests before running them. Read more about runtime dump [here](Sources/RuntimeDump).

`AvitoRunner --help`

# Getting Around the Code

Emcee uses Swift Package Manager for building, testing and exposing the Swift packages. To learn more about each package navigate 
to the corresponding directory under Sources folder. 

# Contributing

We are happy to accept your pull requests. If something does not work for you, please let us know by submitting an issue. 

General commands that help you with a development workflow:

- Generating an Xcode project: `make open`
- Building the binary: `make build`
- Running all tests: `make test`

# Dependencies

Emcee depends heavily on [FBSimulatorControl](https://github.com/beefon/FBSimulatorControl) library, which is a set of APIs to work with iOS Simulator and iOS devices. 
We have a [fork](https://github.com/beefon/FBSimulatorControl) which contains some extensions, so please check it out and 
provide [the binaries](https://github.com/beefon/FBSimulatorControl/releases/tag/avito0.0.1) of the fbxctest and fbsimctl to the Emcee through the CLI. 
