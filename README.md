Welcome to Emcee project, an ultimate solution for running iOS tests in parallel locally and across many Macs. 

Emcee allows you to run UI tests on many physical machines, distributing the work and getting the results of the test run faster.
It manages the order of test execution, the simulators, and maintains the queue with tests that being run. 
It can generate the Junit and trace to make you see how the test run behaved on different machines.

# Getting Started

## Using Emcee

The most easy way to run your tests is to invoke a command line tool.

You will need to have the following build artifacts around:

* .app bundle
* Runner.app bundle

You can use `xcodebuild build-for-testing` command to generate these build artifacts. 

## Running tests locally

To run UI tests locally, execute the following command:

```shell
AvitoRunner runTests \
--fbsimctl "https://github.com/beefon/FBSimulatorControl/releases/download/0.0.3/fbsimctl_20190208T125742.zip" \
--fbxctest "https://github.com/beefon/FBSimulatorControl/releases/download/0.0.3/fbxctest_20190208T125921.zip" \
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

```json
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

## Running tests on remote machines

### Requirements

Since running tests on multiple machines requires sharing of the build artifacts, you should upload them somewhere where they will be
directly accessible via HTTP(S) URL before invoking Emcee. You may consider storing different build artifacts under different URLs,
such that they won't overlap between concurrent builds.

Emcee supports passing http(s) URLs as values to most arguments. The file addressed by URL should be a ZIP file. 
You can refer internals of the archive via URL fragments.

For example:

- App bundle inside archive: `http://myserver.com/MyApp.zip#MyApp.app`
- `xctest` bundle inside archive with `Runner.app`: `http://myserver.com/UITestsRunner.zip#UITestsRunner.app/PlugIns/UITests.xctest`

### Using `distRunTests`

```shell
AvitoRunner distRunTests \
--fbsimctl "https://github.com/beefon/FBSimulatorControl/releases/download/0.0.3/fbsimctl_20190208T125742.zip" \
--fbxctest "https://github.com/beefon/FBSimulatorControl/releases/download/0.0.3/fbxctest_20190208T125921.zip" \
--junit "$(pwd)/test-results/junit.alldestinations.xml" \
--trace "$(pwd)/test-results/trace.alldestinations.json" \
--number-of-retries 1 \
--number-of-simulators 2 \
--app "http://myserver.com/MyApp.zip#MyApp.app" \
--runner "http://myserver.com/MyApp-UITestsRunner.zip#MyApp-UITestsRunner.app" \
--xctest-bundle "http://myserver.com/MyApp-UITestsRunner.zip#MyApp-UITestsRunner.app/PlugIns/UITests.xctest" \
--schedule-strategy "equally_divided" \
--single-test-timeout 100 \
--temp-folder "$(pwd)/tempfolder" \
--test-destinations "destination_iphone_se_ios103.json" \
--destinations "remote_destinations.json" \
--run-id "$(uuidgen)" \
--remote-schedule-strategy progressive
```

Where `remote_destinations.json` could contain the following contents:

```json
[
    {
        "host": "build-agent-macmini-01",
        "port": 22,
        "username": "remote_worker",
        "password": "awesomepassword",
        "remote_deployment_path": "/Users/remote_worker/remote_ui_tests"
    },
    {
        "host": "build-agent-imacpro-02",
        "port": 22,
        "username": "remote_worker",
        "password": "awesomepassword",
        "remote_deployment_path": "/Users/remote_worker/remote_ui_tests"
    }
]
```

Currently, there is no need to prepare the remote machine except installing dependencies from the section below. Emcee will:

- deploy itself
- start the daemon
- download artifacts by using the provided URLs
- start running UI tests 

## Specifying tests to run

You can specify tests you wish to run using arguments or by using JSON file.

### ⚠️: If you don't specify any tests to run explicitly, Emcee will behave differently depending on command:

- for `runTests` command, it will run all available in runtime tests.
- for `distRunTests` command, it will not run anything. If you wish to run all tests, please use `dump` command and form the test plan based on its output.

### Matrix: tests specified by `--only-test` by all test destinations  

You can append multiple `--only-test`. This will form a matrix of tests, each test will be run a single time for each test destination:

```shell
AvitoRunner distRunTests \
    --test-destinations "destination_iphone_se_ios103.json" \
    --only-test "TestClass/testMethod" \
    --only-test "AnotherTestClass/testSomethingImportant"
```
So if you have 2 test destinations, e.g. iOS 11 and iOS 12, and 2 tests, this will form the following test plan:

```
TestClass/testMethod @ iOS 11
AnotherTestClass/testSomethingImportant @ iOS 11
TestClass/testMethod @ iOS 12
AnotherTestClass/testSomethingImportant @ iOS 12
```

### `--test-arg-file` JSON file

This allows to specify a more precise test plan. The contents of this file should adopt the following schema:

```json
{
    "entries": [
        {
            "testToRun": "TestClass/testMethod",
            "testDestination": {"deviceType": "iPhone X", "runtime": "11.0"},
            "numberOfRetries": 2,
            "environment": {
                "TEST_SPECIFIC_ENVS": "if needed"
            }
        },
        {
            "testToRun": "AnotherTestClass/testSomethingImportant",
            "testDestination": {"deviceType": "iPhone SE", "runtime": "12.0"},
            "numberOfRetries": 0,
            "environment": {}
        }
    ]
}
```

This file will form the following test plan:

```
TestClass/testMethod @ iPhone X, iOS 11, up to 3 runs
AnotherTestClass/testSomethingImportant @ iPhone SE, iOS 12, strictly 1 run
```

# What Can This Project Do

The CLI is split into subcommands. Currently the following commands are available:

- `runTests` - actually runs the UI tests on local machine and generates a report.
- `distRunTests` - brings up the queue with tests to run, deploys the required data to the remote machines over SSH and then starts 
remote agents that run UI tests on remote machines. After running all tests, creates a report on local machine.
- `distWork` - starts the runner as a client to the queue server that you start using the `distRunTests` command on the remote machines.
This can be considered as a worker instance of the runner. You don't need to invoke this command manually, Emcee will use it internally.
- `dump` - runs runtime dump. This is a feature that allows you to filter the tests before running them. Read more about runtime dump [here](Sources/RuntimeDump).

`AvitoRunner [subcommand] --help` will print the argument list for each subcommand. 

# Publications

- [Emcee  —  Open Source Tool for iOS UI Testing Infrastructure @ Medium](https://link.medium.com/aHywQuI6jU)
- [NSSpain 2018: UI Testing Infrastructure in Avito @ Vimeo](https://vimeo.com/292738016)

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

## libssh2

`brew install libssh2`

## FBSimulatorControl

Emcee depends heavily on [FBSimulatorControl](https://github.com/beefon/FBSimulatorControl) library, which is a set of APIs to work with iOS Simulator and iOS devices. 
We have a [fork](https://github.com/beefon/FBSimulatorControl) which contains some extensions, so please check it out and 
provide [the binaries](https://github.com/beefon/FBSimulatorControl/releases/tag/avito0.0.1) of the fbxctest and fbsimctl to the Emcee through the CLI. 
