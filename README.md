Welcome to Emcee project, an ultimate solution for running iOS tests in parallel locally and across many Macs. 

Emcee allows you to run UI tests on many physical machines, distributing the work and getting the results of the test run faster.
It manages the order of test execution, the simulators, and maintains the queue with tests that being run. 
It can generate the Junit and trace to make you see how the test run behaved on different machines.

# Getting Started

## Requirements:

- `brew install libssh2`

## Using Emcee

The most easy way to run your tests is to invoke a command line tool.

You will need to have the following build artifacts around:

* .app bundle
* Runner.app bundle

You can use `xcodebuild build-for-testing` command to generate these build artifacts. 

## Running tests locally

To run UI tests locally, execute the following command:

```
AvitoRunner runTests \
--fbsimctl "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.1/fbsimctl_20180831T142903.zip" \
--fbxctest "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.1/fbxctest_20180831T142535.zip" \
--junit "$(pwd)/test-results/junit.alldestinations.xml" \
--trace "$(pwd)/test-results/trace.alldestinations.json" \
--number-of-retries 1 \
--number-of-simulators 2 \
--app "MyApp.app" \
--runner "MyAppUITests-Runner.app" \
--xctest-bundle "MyAppUITests-Runner.app/PlugIns/MyAppUITests.xctest" \
--schedule-strategy "individual" \
--single-test-timeout 100 \
--temp-folder "$(pwd)/tempfolder" \
--test-destinations "destination_iphone_se_ios103.json"
```

Where `destination_iphone_se_ios103.json` might have the folllowing contents:

```
[{
    "testDestination": {
        "deviceType": "iPhone SE",
        "iOSVersion": "10.3"
    },
    "reportOutput": {
        "junit": "test-results/iphone_se_ios_103.xml",
        "tracingReport": "test-results/iphone_se_ios_103.json"
    }
}]
```

## Running tests on a number of machines

You can use `distRunTests` subcommand:

```
AvitoRunner distRunTests \
--fbsimctl "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.1/fbsimctl_20180831T142903.zip" \
--fbxctest "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.1/fbxctest_20180831T142535.zip" \
--junit "$(pwd)/test-results/junit.alldestinations.xml" \
--trace "$(pwd)/test-results/trace.alldestinations.json" \
--number-of-retries 1 \
--number-of-simulators 2 \
--app "MyApp.app" \
--runner "MyAppUITests-Runner.app" \
--xctest-bundle "MyAppUITests-Runner.app/PlugIns/MyAppUITests.xctest" \
--schedule-strategy "equally_divided" \
--single-test-timeout 100 \
--temp-folder "$(pwd)/tempfolder" \
--test-destinations "destination_iphone_se_ios103.json" \
--destinations "remote_destinations.json" \
--run-id "$(uuidgen)" \
--remote-schedule-strategy progressive
```

Where `remote_destinations.json` could contain the following contents:

```
[
    {
        "host": "build-agent-macmini-01",
        "port": 22,
        "username": "remote_worker",
        "password": "awesomepassword",
        "remote_deployment_path": "/Users/remote_worker/remote_ui_tests",
        "number_of_simulators": 2
    },
    {
        "host": "build-agent-imacpro-02",
        "port": 22,
        "username": "remote_worker",
        "password": "awesomepassword",
        "remote_deployment_path": "/Users/remote_worker/remote_ui_tests",
        "number_of_simulators": 4
    }
]
```

Currently, there is no need to prepare the remote machine. Emcee will:

- deploy itself and build artifacts over SSH
- start the daemon
- start running UI tests automatically

# What Can This Project Do

The CLI is split into subcommands. Currently the following commands are available:

- `runTests` - actually runs the UI tests on local machine and generates a report.
- `distRunTests` - brings up the queue with tests to run, deploys the required data to the remote machines over SSH and then starts 
remote agents that run UI tests on remote machines. After running all tests, creates a report on local machine.
- `distWork` - starts the runner as a client to the queue server that you start using the `distRunTests` command on the remote machines.
This can be considered as a worker instance of the runner.
- `dump` - runs runtime dump. This is a feature that allows you to filter the tests before running them. Read more about runtime dump [here](Sources/RuntimeDump).

`AvitoRunner [subcommand] --help` will print the argument list for each subcommand. 

# Getting Around the Code

Emcee uses Swift Package Manager for building, testing and exposing the Swift packages. To learn more about each package navigate 
to the corresponding directory under Sources folder. 

# Contributing

We are happy to accept your pull requests. If something does not work for you, please let us know by submitting an issue. 

General commands that help you with a development workflow:

- Generating an Xcode project: `make open`
- Building the binary: `make build`
- Running unit tests: `make test`
- Running integration tests: `make integration-test`

# Dependencies

Emcee depends heavily on [FBSimulatorControl](https://github.com/beefon/FBSimulatorControl) library, which is a set of APIs to work with iOS Simulator and iOS devices. 
We have a [fork](https://github.com/beefon/FBSimulatorControl) which contains some extensions, so please check it out and 
provide [the binaries](https://github.com/beefon/FBSimulatorControl/releases/tag/avito0.0.1) of the fbxctest and fbsimctl to the Emcee through the CLI. 
