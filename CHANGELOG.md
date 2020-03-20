# Change Log

All notable changes to this project will be documented in this file.

## 2020-03-20

- Emcee now allows you to control automatic simulator deletion by setting `simulatorOperationTimeouts.automaticSimulatorDelete` in test arg file to a positive value in seconds. Deletion happens only after simulator is shut down, e.g. automatically. When it is needed again, it will be recreated and booted. Deleting simulators allows to free up disk space. Example:

```json
{
    "simulatorOperationTimeouts": {
        "create": 30,
        "boot": 180,
        "shutdown": 20,
        "delete": 20,
        "automaticSimulatorShutdown": 600,
        "automaticSimulatorDelete": 600
    }
}
```

Confguration above defines the following behaviour:

- When simulator becomes and stays idle, shut it down after 600 seconds.
- If simulator still unused after 600 seconds after shutting it down, delete it.

## 2020-02-19

- `toolResources` field in test arg file has gone. Inline `simulatorControlTool` and `testRunnerTool` values in test arg file instead of wrapping them in `toolResources`.

- Test arg file now required to pass `simulatorOperationTimeouts` field. This allows to set time out operations for various simulator operations like boot, create, delete and shutdown. Previously, Emcee has had a hardcoded values for these operations. Previously hard coded values are:

```json
{
    "simulatorOperationTimeouts": {
        "create": 30,
        "boot": 180,
        "shutdown": 20,
        "delete": 20,
        "automaticSimulatorShutdown": 3600
    }
}
```

- Emcee now allows you to control automatic simulator shutdown by setting `simulatorOperationTimeouts.automaticSimulatorShutdown` in test arg file to a positive value in seconds after which simulator will be shut down if it stays idle. When it is needed again, it will be booted. Shutting down simulators allows to free up some RAM and reduce swap size. 

## 2020-02-14

- `ToolchainConfiguration` object and `toolchainConfiguration` field have been removed from test arg file, because this object contained only `developerDir` value. You must provide a value via `developerDir` field in test arg file instead.

## 2020-02-07

- Added remote cache support for runtime dump action. Provide `--remote-cache-config` argument with JSON config for remote cache to use it. Next time runtime dump action will be executed Emcee will try to obtain cached version of runtime dump results from remote cache storage. See Wiki for more details.

## 2020-01-16

- Fixed a bug: when Emcee fails to execute a test because of underlying error (e.g. failed to fetch a file, failed to boot simulator), worker wouldn't send back a test failure result. This would result to an infinitely processing buckets on worker. Now it will report back a test failure.

- Changed the way Emcee manages plugins. They now start right before Runner is about to start tests, and stopped after that. Plugins are started on the workers only.

- `plugins` key is now removed from Queue Server Run Configuration

- `testArgFile` entries now expect to have `plugins` key.

## 2020-01-09

- Fixed a bug when Emcee would fail to fetch contents of URL if server returns an error (e.g. 404 status). All sequential attempts to fetch the contents of the URL would result to dead lock. Now Emcee correctly handles this.

## 2019-12-30

- Simulator settings now provided as JSON inside test arg file instead of URLs to JSON inside ZIP archive. See `SimulatorSetttings`, `SimulatorLocalizationSettings` and `WatchdogSettings` for format description.  

## 2019-12-25

- `auxiliaryResources` key has been removed from queue server run configuration JSON file because only plugin URLs are required in order to start up the queue. 

- `plugins` key must now be present in queue server run configuration. This is an array of URLs to ZIP files with `emceeplugin` bundles.

## 2019-12-04

- Emcee starts workers differently now. Instead of deploying itself to all worker machines and then performing worker start, it now deploys and starts the worker immediately after that.

- Instead of using fixed 4 threads to deploy workers, Emcee uses variable thread count now to speed up deployment process. 

- Emcee specifies `TMPDIR` environment variable when it launches `fbxctest` process now so `fbxctest` shouldn't put litter into `/tmp/` shared folder anymore.

- Emcee evicts elements from its file cache if they weren't used for more than 1 hour. Previously the TTL was set to 6 hours.

## 2019-12-02

- Test arg file entries are expected to have `simulatorSettings` and `testTimeoutConfiguration` fields present. Previously these fields were part of queue server run configuration. By moving these values into test arg file it is now possible to specify them on per-test basis.

## 2019-11-14

- Emcee will try to clean up dead simulator cache before executing tests by deleting `simulator_folder/data/Library/Caches/com.apple.containermanagerd/Dead` folder.

## 2019-11-12

- Emcee changed a way how it creates its simulators. It still creates a private folder with private simulators, but when Emcee attempts to execute test, it will create a symbolic link to the private simulator, and pass it to `fbxctest`. 

- Prebuilt `fbxctest` and `fbsimctl` have been updated to support Xcode 11.2, you may find their URLs in README file. 

- Recently some work has been done in order to support `xcodebuild` test execution. It is worth mentioning that only `fbxctest` and  `fbsimctl` are still fully supported; `xcrun simctl` and `xcodebuild` are not fully supported yet.

## 2019-10-30

- `SimulatorInfo` type has been deleted. Use `Simulator` model from `SimulatorPool`.

## 2019-10-29

- `dump` command now expects `--test-arg-file` argument to be provided. It iterates over its `entry` objects and performs runtime dump for each `buildArtifacts.xcTestBundle`. It then merges the result and writes it out into the given value of `--output` argument. Thus, the resulting JSON now contains an array of results instead of a single result.

- `--app`, `--fbxctest`, `--fbsimctl`, `--test-destinations`, `--xctest-bundle` arguments have been removed from `dump` command. Pass these values via test arg file.

- Runtime dump now uses `environment` from test arg file. It does not pass Emcee process environment into test bundle anymore  when performing runtime dump.

- Use can control how many times runtime dump operation can be retried by specifying `numberOfRetries` for test entry. Previously Emcee had 5 hardcoded retries, and now this value must be set via test arg file.

- `--fbxctest` and `--fbsimctl` arguments have been removed from `runTestsOnRemoteQueue` command. It now uses test arg file entries to obtain simulator control tool and test runner tool.

## 2019-10-28

### Changed

- `environment` and `testType` fiels are required to be present in test arg file. 
```json
    ...
    "environment": {"ENV1": "VAL1", ...},
    "testType": "uiTest",  # supported values are "appTest", "logicTest", "uiTest"
    ...
```

- Test arg file JSON entries is now expected to have `toolResources` field. This field describes the tools used to perform testing. This is an object with `testRunnerTool` and `simulatorControlTool`. Example:

```json
    ...
    "toolResources": {
        "testRunnerTool": {"toolType": "fbxctest", "fbxctestLocation": "http://example.com/fbxctest.zip"},
        "simulatorControlTool": {"toolType": "fbsimctl", "location": "http://example.com/fbsimctl.zip"}
    },
    ...
```

## 2019-10-25

### Changed

- During the last refactorings a bug appeared: Emcee would create simulators inside the same folder. This has now been fixed. 

## 2019-10-18

### Changed

- `auxiliaryResources.toolResources` field format of queue server run configuration file has changed. Previously, you would pass a single string as a value to `testRunnerTool` field and it would resolve to `fbxctest` runner tool. Now this field is expected to be an object with `toolType` (must be either `fbxctest` or `xcodebuild`, the latter is not supported yet) field and optional `fbxctestLocation` filed (must be URL of `fbxctest`) in case if you are using `fbxctest` to run tests. To adopt and keep using `fbxctest` as test runner tool you can pass this object in your queue server run configuration file: `{"testRunnerTool": {"toolType": "fbxctest", "fbxctestLocation": "your URL"}}`

## 2019-09-30

### Changed

- Fixed a bug when Emcee would fail to start with error `errno 2` if default cache folder at `~/Library/Caches/ru.avito.Runner.cache` does not exist.

## 2019-09-27

### Changed

- Fixed a bug when worker does not drop already processed buckets. This would make logs vary large and unreadable.

## 2019-09-24

### Changed

- Test arg file is now expected to have `priority` and `testDestinationConfigurations` top level fields. This substitues now removed `--priority` and `--test-destinations` arguments from `runTestsOnRemoteQueue` command. Emcee will now use correct test destination for a corresponding test arg file entry when performing a runtime dump instead of using a first test destination from the `--test-destination` file.

## 2019-09-23

### Changed

- Emcee now reports some errors occurred when attempting to run fbxctest tool as test failure in opposite to failing with a critical error. This applies to misconfiguration, e.g. if you do not pass a location of app bundle when attempting to run UI or application test.

- Fixed a bug when after processing runtime dump, Emcee would schedule a redundant amount of tests to the queue.

## 2019-09-20

### Changed

- Previously, runtime dump would group all entries by their build artifacts and then perform dump in order to validate the provided tests to run. This logic has been removed. Now runtime dump performs a single dump for each test arg file entry. Pass a list of tests into `testsToRun` field to reduce number of runtime dumps.

- `scheduleStrategy` root field has been moved from test arg file JSON to each test arg file entry. This allows you to specify schedule strategy on per-test-arg-file-entry basis.

- Now Emcee respects toolchain configuration when performing a runtime dump for each test arg file entry. Previously, it would perform runtime dump using current developer dir provided by `xcode-select`.

## 2019-09-19

### Changed

- Updated README file to refer new builds of idb fork. Now they work correctly with Xcode 11 GM 2.

- Fixed a bug when workers would start and exit immediately without connecting to a queue server.

- Emcee now dynamically schedules jobs after runtime dump finishes. It helps to speed up the test run. For example, if you run multiple test bundles, Emcee will now schedule tests from each bundle one by one after performing a runtime dump for each test bundle in opposite to scheduling all tests from all test bundles in one go. By the moment when the last set of tests from the last test bundle will be scheduled to the queue, test results for the first test bundle likely will be available.

## 2019-09-10

### Added

- New Graphite metric `queue.worker.status.<worker_name>.[alive|blocked|notRegistered|silent]` allows you to track the statuses of your workers.

### Changed

- Updated the way how workers report test results back to the queue. Report request hardcoded timeout of 10 seconds has been removed. Workers now rely on the `NSURLTask` API default timeouts. This allows the queue to process network request for as long as it would need. This also fixes an issue when worker decides that such request has timed out, it will re-attempt to report test results again, making the queue block the worker.

## 2019-09-06

### Changed

- When you attempt to run tests using `runTestsOnRemoteQueue` command, and if shared queue is not running yet, previously Emcee would start the queue on a remote machine and then will deploy and start workers for that queue from inside `runTestsOnRemoteQueue` command. Now the behaviour has changed: once started, the queue will deploy and start workers for itself independently from `runTestsOnRemoteQueue` command. 

- Emcee now applies a shared lock to a whole file cache (`~/Library/Caches`) when it unzips downloaded files. Previously multiple Emcee processes may run a race for the same zip file.

### Removed

- Removed `--analytics-configuration` and `--worker-destinations-location` arguments from `runTestsOnRemoteQueue` command. Now you have to pass them via `--queue-server-configuration-location` JSON file. Corresponding `QueueServerRunConfiguration` Swift model has been updated to include new `workerDeploymentDestinations` field, and `analyticsConfiguration` field has been around for a while.
