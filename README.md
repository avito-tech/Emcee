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

## Command Line Interface

The CLI is split into subcommands. Currently the following commands are available:

- `runTestsOnRemoteQueue` - brings up the shared queue server on a dedicated machine, submits a job to it, and then starts remote workers that run UI tests on remote machines. After running all tests, creates a report on a local machine.
- `dump` - runs runtime dump. This is a feature that allows you to filter the tests before running them. Read more about runtime dump [here](Sources/RuntimeDump).

## Running tests on remote machines

### Requirements

Since running tests on multiple machines requires sharing of the build artifacts, you should upload them somewhere where they will be directly accessible via HTTP(S) URL before invoking Emcee. You may consider storing different build artifacts under different URLs, such that they won't overlap between concurrent builds.

Emcee supports passing http(s) URLs as values to most arguments. The file addressed by URL should be a ZIP file. 
You can refer internals of the archive via URL fragments.

For example:

- App bundle inside archive: `http://example.com/MyApp.zip#MyApp.app`
- `xctest` bundle inside archive with `Runner.app`: `http://example.com/UITestsRunner.zip#UITestsRunner.app/PlugIns/UITests.xctest`

### `runTestsOnRemoteQueue` Command

```bash
Emcee runTestsOnRemoteQueue \
    --queue-server-destination "queue_server_machine.json" \
    --queue-server-run-configuration-location "http://example.com/queue_config.json" \
    --test-arg-file "test-arg-file.json" \
    --run-id "some_random_job_id_eg_uuidgen" \
    --temp-folder "/path/to/folder/where/emcee/can/put/stuff"
```

#### `--queue-server-destination` argument

This is a JSON file that describes the SSH credentials of the host which will run shared queue Emcee process. It might contain the following contents:

```json
[
    {
        "host": "build-agent-macmini-01",
        "port": 22,
        "username": "remote_worker",
        "password": "awesomepassword",
        "remote_deployment_path": "/Users/remote_worker/remote_ui_tests.noindex/"
 }
]
```

In the example above we dedicate `"build-agent-macmini-01"` host to contain the shared queue. Shared queue will be started automatically when you submit the first job.

> **Hint:** if you want to parallelize tests only on local machine, consider creating a file that describes `localhost` credentials.

In the example above, Emcee will create Junit for `iPhone X @ iOS 12.4` tests in the specified location (`/path/to/test-results/junit.xml`).

#### `--test-arg-file` argument

This file describes a precise test plan to execute. The contents of this file should adopt the following schema:

```json
{
    "priority": 500,
    "entries": [
        {
            "testsToRun": ["TestClass/testMethod"],
            "buildArtifacts": {
                "appBundle": "http://example.com/MyApp.zip#MyApp.app",
                "runner": "http://example.com/MyApp-Runner.zip#MyApp-Runner.app",
                "xcTestBundle": "http://example.com/MyApp-Runner.zip#MyApp-Runner.app/PlugIns/UITests.xctest"
            },
            "testDestination": {"deviceType": "iPhone X", "runtime": "11.0"},
            "numberOfRetries": 2,
            "environment": {
                "TEST_SPECIFIC_ENVS": "if needed"
            },
            "scheduleStrategy": "progressive",
            "toolResources": {
                "simulatorControlTool": {
                    "toolType": "fbsimctl", 
                    "location": "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.6/fbsimctl_20191111T182802.zip"
                },
                "testRunnerTool": {
                    "toolType": "fbxctest",
                    "fbxctestLocation": "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.6/fbxctest_20191108T173517.zip"
                }
            },
            "toolchainConfiguration": {
                "developerDir": {"kind": "current"}
            }
        },
        {
            "testsToRun": ["AnotherTestClass/testSomethingImportant"],
            "buildArtifacts": { ... },
            "testDestination": {"deviceType": "iPhone SE", "runtime": "12.0"},
            "numberOfRetries": 0,
            "environment": {},
            "scheduleStrategy": "progressive",
            "toolResources": {
                "simulatorControlTool": {
                    "toolType": "fbsimctl", 
                    "location": "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.6/fbsimctl_20191111T182802.zip"
                },
                "testRunnerTool": {
                    "toolType": "fbxctest",
                    "fbxctestLocation": "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.6/fbxctest_20191108T173517.zip"
                }
            },
            "toolchainConfiguration": {
                 "developerDir": {
                     "kind": "useXcode",
                     "CFBundleShortVersionString:": "10.3"
                 }
            }
        }
    ],
    "testDestinationConfigurations": [
        {
            "testDestination": {"deviceType": "iPhone SE", "runtime": "12.0"},
            "reportOutput": {"junit": "/path/to/junit/specific/for/iphone_se/ios12.0/junit.xml"}
        },
        {
            "testDestination": {"deviceType": "iPhone X", "runtime": "11.0"},
            "reportOutput": {"junit": "/path/to/junit/specific/for/iphone_x/ios11.0/junit.xml"}
        }
    ]
}
```

> **Hint:** If you want to run a single test multiple times, you can repeat it in `--test-arg-file` multiple times. 

> **WARNING**: You must install Xcode simulators on each worker machine in order to run tests. Go to `Xcode.app` -> `Preferences` -> `Components`.

Read more about test arg file format in `TestArgFile.swift`.

# Publications

- [Emcee  —  Open Source Tool for iOS UI Testing Infrastructure @ Medium](https://link.medium.com/aHywQuI6jU)
- [NSSpain 2018: UI Testing Infrastructure in Avito @ Vimeo](https://vimeo.com/292738016)

# Getting Around the Code

Emcee uses Swift Package Manager for building, testing and exposing the Swift packages. To learn more about each package navigate to the corresponding directory under Sources folder. 

# Contributing

We are happy to accept your pull requests. If something does not work for you, please let us know by submitting an issue. 

General commands that help you with a development workflow:

- Generating an Xcode project: `make open`
- Building the binary: `make build`
- Running unit tests: `make test-parallel`
- Running integration tests: `make integration-test`

# Dependencies

## libssh2

`brew install libssh2`

## FBSimulatorControl

Emcee depends heavily on [FBSimulatorControl](https://github.com/beefon/FBSimulatorControl) library, which is a set of APIs to work with iOS Simulator and iOS devices. 
We have a [fork](https://github.com/beefon/FBSimulatorControl) which contains some extensions, so please check it out and 
provide [the binaries](https://github.com/beefon/FBSimulatorControl/releases/tag/avito0.0.5) of the fbxctest and fbsimctl to the Emcee. 
