![Emcee Banner](https://raw.github.com/avito-tech/Emcee/master/Resources/banner.png)

Welcome to Emcee project, an ultimate solution for running iOS tests in parallel locally and across many Macs. 

Emcee allows you to run UI tests on many physical machines, distributing the work and getting the results of the test run faster. Shared queue manages the order of test execution. Emcee workers execute tests and maintain lifecycle of their simulators automatically. Emcee can generate the Junit and trace reports to make you see how the test run behaved on different machines.

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

# Getting started

In this guide will demonstrate how to use Emcee. We will use two MacOS machines to run unit and UI tests from a sample project. You can also use a single machine to try out Emcee to see if it works for your project. In this case, a single machine will act as a `queue` and a `worker` simultaneously. Alternatively, you can scale this guide to as many machines as you have.

If you encounter any issues while proceeding through the guide, please open an issue or reach out via https://t.me/emcee_ios.

## Table of contents

1. [Setting up machines](#setup)
1. [Building the sample project](#building_sample)
1. [Running tests using Emcee](#running_emcee)
	1. [Tests without a host application](#tests_without_host)
	1. [Tests with a host application](#tests_with_host)
	1. [XCUI tests](#xcui_tests)
1. [Advanced Emcee configuration](#advanced_emcee)

## Setting up machines <a name="setup"></a>

You will need to grant SSH access to your machines.

<details>
<summary>Expand to see how to set up your machines.</summary>

We will be using two machines: `ios-build-machine77` and `ios-build-machine78`.

![machines](https://raw.github.com/avito-tech/Emcee/master/Resources/machines.webp)

* `ios-build-machine77` will be a worker and a queue - it will provide workers with tests to execute and execute some of those tests.
* `ios-build-machine78` will be a worker - it will only execute tests.

Both machines are set up with a standard non-administrator user `emcee` and a `qwerty` password.

Install [Xcode](https://developer.apple.com/download/all/) and `sudo xcode-select --switch /Applications/Xcode.app` on all of your machines.

We will use `Xcode 13.0 (13A233)` and the `iOS 15.0` simulator runtime bundled with this Xcode. If you want to use a specific version of simulator runtime, proceed to `Xcode -> Preferences... -> Components -> Simulators` and install the runtime on all the worker machines, where you want the tests to execute with the specific runtime version.

Emcee uses ssh to deploy itself to the machines specified as `queue` and `workers`. Enable SSH in your `System Preferences -> Sharing -> Remote Login`. To open this pane execute:

```sh
$ open "x-apple.systempreferences:com.apple.preferences.sharing?Services_RemoteLogin"
```

![Remote Login SSH Settings](https://raw.github.com/avito-tech/Emcee/master/Resources/remote_login_ssh_settings.webp)

Now make sure that machines are accessible by ssh. For example:

```sh
ssh emcee@ios-build-machine77
```

If your machines are not accessible by DNS, use their IP addresses instead. You can check IP address in `System Preferences -> Sharing`. Please note IP addresses may change over time. To open this pane execute:

```sh
$ open "x-apple.systempreferences:com.apple.preferences.sharing"
```

</details>

## Building the sample project <a name="building_sample"></a>

In this step, we will build a sample project that features different types of tests. Xcode and `xcodebuild` will produce build artifacts in derived data.

<details>
<summary>Expand to see how to build the sample project for testing purposes.</summary> 

You can run this step from either machine. Clone the sample project:

```sh
cd ~
git clone https://github.com/avito-tech/Emcee.git
cd Emcee/Samples/EmceeSample
```

To build the project, create a simulator:

```sh
xcrun simctl create '15.0' 'iPhone X' 'iOS15.0'
```

Now run xcodebuild:

```sh
xcodebuild build-for-testing \
	-project EmceeSample.xcodeproj \
	-destination "platform=iOS Simulator,name=15.0,OS=15.0" \
	-scheme AllTests \
	-derivedDataPath derivedData
```

Xcodebuild will place the build products in:

```sh
derivedData/Build/Products/Debug-iphonesimulator
```

</details>

## Running tests using Emcee <a name="running_emcee"></a>

Now that the machines are ready, and the project is built, download Emcee on the same machine where you built the project by running:

```sh
curl -L https://github.com/avito-tech/Emcee/releases/download/16.0.0/Emcee -o Emcee && chmod +x Emcee
```

If you download Emcee using a browser you will need to clear attributes and set the executable bit:

```sh
xattr -c Emcee && chmod +x Emcee
```

With Emcee installed it is finally time to run the tests. The sample project includes [3 test types](https://github.com/avito-tech/Emcee/wiki/Build-Artifacts-and-Test-Types):

* Tests that don't require a host application
* Tests that require a host application
* XCUI tests

### Tests without a host application <a name="tests_without_host"></a>

Let's first run tests that don't require a host application. We will be using the `runTests` command:

```sh
./Emcee runTests \
	--queue "ssh://emcee:qwerty@ios-build-machine77" \
	--worker "ssh://emcee:qwerty@ios-build-machine77" \
	--worker "ssh://emcee:qwerty@ios-build-machine78" \
	--device "iPhone X" \
	--runtime "15.0" \
	--test-bundle derivedData/Build/Products/Debug-iphonesimulator/EmceeSampleTestsWithoutHost.xctest \
	--junit tests_without_host_junit.xml
```

Here is what these options stand for:

* `--queue` - is a URL of a machine that will serve workers with tests
* `--worker` - is a URL of a machine that will execute tests that it queries from the `queue`
* `--device` and `--runtime` - are options that specify which simulators will run the tests
* `--test-bundle` - is a path to the xctest bundle
* `--junit` - is a path to the JUnit xml that will contain the result of the test run

You can find more about all options accepted by `runTests` and how to specify them using `Emcee runTests -h`.

After the test finishes, Emcee will create a `tests_without_host_junit.xml` file. The JUnit report contains four `testcase` entries matching the four test methods from the `EmceeSampleTestsWithoutHost.xctest` test bundle.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="xctest" tests="4" failures="1">
    <testsuite name="EmceeSampleTestsWithoutHost" tests="4" failures="1">
        <testcase classname="EmceeSampleTestsWithoutHost" name="test_0___from_tests_without_host___that_always_succeeds" timestamp="2021-12-29T01:15:16+03:00" time="0.012196063995361328"></testcase>
        <testcase classname="EmceeSampleTestsWithoutHost" name="test_1___from_tests_without_host___that_always_succeeds" timestamp="2021-12-29T01:15:27+03:00" time="0.02156198024749756"></testcase>
        <testcase classname="EmceeSampleTestsWithoutHost" name="test_2___from_tests_without_host___that_always_succeeds" timestamp="2021-12-29T01:15:36+03:00" time="0.021990060806274414"></testcase>
        <testcase classname="EmceeSampleTestsWithoutHost" name="test___from_tests_without_host___that_always_fails" timestamp="2021-12-29T01:15:31+03:00" time="0.1255110502243042">
            <failure message="failed - Failure from tests without host">/Users/emcee/Emcee/SampleProject/EmceeSampleTestsWithoutHost/EmceeSampleTestsWithoutHost.swift:17</failure>
            <failure message="failed - Failure from tests without host">/Users/emcee/Emcee/SampleProject/EmceeSampleTestsWithoutHost/EmceeSampleTestsWithoutHost.swift:17</failure>
        </testcase>
    </testsuite>
</testsuites>
```

For a more sophisticated test reporting mechanism such as Allure, check out the [Plugins documentation](https://github.com/avito-tech/Emcee/wiki/Plugins).

### Tests with a host application <a name="tests_with_host"></a>

Now let's try running tests that require a host application. Host application path is specified using the `--app` option. For example:

```sh
./Emcee runTests \
    --queue "ssh://emcee:qwerty@ios-build-machine77" \
    --worker "ssh://emcee:qwerty@ios-build-machine77" \
    --worker "ssh://emcee:qwerty@ios-build-machine78" \
    --device "iPhone X" \
    --runtime "15.0" \
    --app derivedData/Build/Products/Debug-iphonesimulator/EmceeSample.app \
    --test-bundle derivedData/Build/Products/Debug-iphonesimulator/EmceeSample.app/PlugIns/EmceeSampleHostedTests.xctest \
    --junit tests_with_host_junit.xml
```

To get a visual confirmation that Emcee is running the tests, you can open the Simulator app on the worker machines:

```sh
open "$(xcode-select -p)"/Applications/Simulator.app
```

### XCUI tests <a name="xcui_tests"></a>

Finally, we will run XCUI tests by adding a `--runner` option and changing the `--test-bundle` option to the XCUI test bundle:

```sh
./Emcee runTests \
    --queue "ssh://emcee:qwerty@ios-build-machine77" \
    --worker "ssh://emcee:qwerty@ios-build-machine77" \
    --worker "ssh://emcee:qwerty@ios-build-machine78" \
    --device "iPhone X" \
    --runtime "15.0" \
    --runner derivedData/Build/Products/Debug-iphonesimulator/EmceeSampleUITests-Runner.app \
    --app derivedData/Build/Products/Debug-iphonesimulator/EmceeSample.app \
    --test-bundle derivedData/Build/Products/Debug-iphonesimulator/EmceeSampleUITests-Runner.app/PlugIns/EmceeSampleUITests.xctest \
    --junit ui_tests_junit.xml
```

This is how the test run will look:

![running_tests](https://raw.github.com/avito-tech/Emcee/master/Resources/running_tests_vstack.webp)

## Advanced Emcee configuration <a name="advanced_emcee"></a>

Complete documentation is available in our [Wiki](https://github.com/avito-tech/Emcee/wiki).

`runTests` command allows you to get Emcee up and running quickly; however, it doesn't allow for a lot of configuration. On the other hand, `runTestsOnRemoteQueue` command allows for fine-grained control of how your tests execute. To get started with `runTestsOnRemoteQueue` check out the [Queue Server Configuration](https://github.com/avito-tech/Emcee/wiki/Queue-Server-Configuration) and [Test Arg File](https://github.com/avito-tech/Emcee/wiki/Test-Arg-File) wiki pages.

# Publications

- [Emcee  —  Open Source Tool for iOS UI Testing Infrastructure @ Medium](https://link.medium.com/aHywQuI6jU)
- [NSSpain 2018: UI Testing Infrastructure in Avito @ Vimeo](https://vimeo.com/292738016)

# Getting Around the Code

Emcee uses Swift Package Manager for building, testing and exposing the Swift packages.

To start exploring code open `Package.swift` in Xcode 13 or execute `make open` to generate and open Xcode project.

# Contributing

We are happy to accept your pull requests. If something does not work for you, please let us know by submitting an issue. Read the docs and suggest improvements to them as well!

General commands that help you with a development workflow:

- To open a package in Xcode: `make open`
- To generate `Package.swift`: `make package`
- To build the binary into `.build/debug/Emcee`: `make build`
- To run unit tests: `make test`

`Package.swift` file is generated automatically. You must update it before submitting a pull request (run `make package`). CI checks will fail if you forget to do so.
