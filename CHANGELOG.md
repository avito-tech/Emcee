# Change Log

All notable changes to this project will be documented in this file.

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
