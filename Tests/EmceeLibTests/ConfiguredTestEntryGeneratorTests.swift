import AppleTestModels
import AppleTestModelsTestHelpers
import BuildArtifacts
import BuildArtifactsTestHelpers
import CommonTestModels
import CommonTestModelsTestHelpers
import EmceeLib
import EmceeLogging
import Foundation
import MetricsExtensions
import QueueModels
import QueueModelsTestHelpers
import ScheduleStrategy
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestArgFile
import TestDestination
import TestDiscovery
import TestHelpers
import XCTest

final class ConfiguredTestEntryGeneratorTests: XCTestCase {
    lazy var argFileTestToRun1 = TestName(className: "classFromArgs", methodName: "test1")
    lazy var argFileTestToRun2 = TestName(className: "classFromArgs", methodName: "test2")
    lazy var buildArtifacts = AppleBuildArtifactsFixture().appleBuildArtifacts()
    lazy var simDeviceType = SimDeviceTypeFixture.fixture()
    lazy var simRuntime = SimRuntimeFixture.fixture()
    lazy var argFileDestination = TestDestination.appleSimulator(
        simDeviceType: simDeviceType,
        simRuntime: simRuntime
    )
    lazy var simulatorSettings = SimulatorSettingsFixtures().simulatorSettings()
    lazy var testTimeoutConfiguration = TestTimeoutConfiguration(singleTestMaximumDuration: 10, testRunnerMaximumSilenceDuration: 20)
    lazy var analyticsConfiguration = AnalyticsConfiguration()
    lazy var unsplitScheduleStrategy = ScheduleStrategy(testSplitterType: .unsplit)

    lazy var validatedEntries: [ValidatedTestEntry] = {
        return [
            ValidatedTestEntry(
                testName: argFileTestToRun1,
                testEntries: [TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1")],
                buildArtifacts: buildArtifacts
            ),
            ValidatedTestEntry(
                testName: argFileTestToRun2,
                testEntries: [TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test2")],
                buildArtifacts: buildArtifacts
            )
        ]
    }()
    
    func test() throws {
        let generator = SimilarlyConfiguredTestEntryGenerator(
            analyticsConfiguration: analyticsConfiguration,
            validatedEntries: validatedEntries,
            testArgFileEntry: TestArgFileEntry(
                buildArtifacts: buildArtifacts,
                developerDir: .current,
                environment: [:],
                userInsertedLibraries: [],
                numberOfRetries: 10,
                testRetryMode: .retryOnWorker,
                logCapturingMode: .noLogs,
                runnerWasteCleanupPolicy: .clean,
                pluginLocations: [],
                scheduleStrategy: unsplitScheduleStrategy,
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: simulatorSettings,
                testDestination: argFileDestination,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testAttachmentLifetime: .deleteOnSuccess,
                testsToRun: [.testName(argFileTestToRun1)],
                workerCapabilityRequirements: [],
                collectResultBundles: false
            ),
            logger: .noOp
        )
        
        let expected = SimilarlyConfiguredTestEntries(
            testEntries: [
                TestEntryFixtures.testEntry(testName: argFileTestToRun1),
            ],
            testEntryConfiguration: TestEntryConfigurationFixtures()
                .with(
                    appleTestConfiguration: AppleTestConfigurationFixture()
                        .with(buildArtifacts: buildArtifacts)
                        .with(simulatorSettings: simulatorSettings)
                        .with(simDeviceType: simDeviceType)
                        .with(simRuntime: simRuntime)
                        .with(testTimeoutConfiguration: testTimeoutConfiguration)
                        .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], userInsertedLibraries: [], numberOfRetries: 10, testRetryMode: .retryOnWorker, logCapturingMode: .noLogs, runnerWasteCleanupPolicy: .clean))
                        .appleTestConfiguration()
                )
                .testEntryConfiguration()
        )
        
        assert {
            try generator.createSimilarlyConfiguredTestEntries()
        } equals: {
            expected
        }
    }
    
    func test_repeated_items() {
        let generator = SimilarlyConfiguredTestEntryGenerator(
            analyticsConfiguration: analyticsConfiguration,
            validatedEntries: validatedEntries,
            testArgFileEntry: TestArgFileEntry(
                buildArtifacts: buildArtifacts,
                developerDir: .current,
                environment: [:],
                userInsertedLibraries: [],
                numberOfRetries: 10,
                testRetryMode: .retryOnWorker,
                logCapturingMode: .noLogs,
                runnerWasteCleanupPolicy: .clean,
                pluginLocations: [],
                scheduleStrategy: unsplitScheduleStrategy,
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: simulatorSettings,
                testDestination: argFileDestination,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testAttachmentLifetime: .deleteOnSuccess,
                testsToRun: [.testName(argFileTestToRun1), .testName(argFileTestToRun1)],
                workerCapabilityRequirements: [],
                collectResultBundles: false
            ),
            logger: .noOp
        )
        
        let expected = SimilarlyConfiguredTestEntries(
            testEntries: [
                TestEntryFixtures.testEntry(testName: argFileTestToRun1),
                TestEntryFixtures.testEntry(testName: argFileTestToRun1),
            ],
            testEntryConfiguration: TestEntryConfigurationFixtures()
                .with(
                    appleTestConfiguration: AppleTestConfigurationFixture()
                        .with(buildArtifacts: buildArtifacts)
                        .with(simulatorSettings: simulatorSettings)
                        .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], userInsertedLibraries: [], numberOfRetries: 10, testRetryMode: .retryOnWorker, logCapturingMode: .noLogs, runnerWasteCleanupPolicy: .clean))
                        .with(simDeviceType: simDeviceType)
                        .with(simRuntime: simRuntime)
                        .with(testTimeoutConfiguration: testTimeoutConfiguration)
                        .appleTestConfiguration()
                )
                .testEntryConfiguration()
        )

        assert {
            try generator.createSimilarlyConfiguredTestEntries()
        } equals: {
            expected
        }
    }
    
    func test__all_available_tests() {
        let generator = SimilarlyConfiguredTestEntryGenerator(
            analyticsConfiguration: analyticsConfiguration,
            validatedEntries: validatedEntries,
            testArgFileEntry: TestArgFileEntry(
                buildArtifacts: buildArtifacts,
                developerDir: .current,
                environment: [:],
                userInsertedLibraries: [],
                numberOfRetries: 10,
                testRetryMode: .retryOnWorker,
                logCapturingMode: .noLogs,
                runnerWasteCleanupPolicy: .clean,
                pluginLocations: [],
                scheduleStrategy: unsplitScheduleStrategy,
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: simulatorSettings,
                testDestination: argFileDestination,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testAttachmentLifetime: .deleteOnSuccess,
                testsToRun: [.allDiscoveredTests],
                workerCapabilityRequirements: [],
                collectResultBundles: false
            ),
            logger: .noOp
        )
        
        let expected = SimilarlyConfiguredTestEntries(
            testEntries: [
                TestEntryFixtures.testEntry(testName: argFileTestToRun1),
                TestEntryFixtures.testEntry(testName: argFileTestToRun2),
            ],
            testEntryConfiguration: TestEntryConfigurationFixtures()
                .with(
                    appleTestConfiguration: AppleTestConfigurationFixture()
                        .with(buildArtifacts: buildArtifacts)
                        .with(simDeviceType: simDeviceType)
                        .with(simRuntime: simRuntime)
                        .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], userInsertedLibraries: [], numberOfRetries: 10, testRetryMode: .retryOnWorker, logCapturingMode: .noLogs, runnerWasteCleanupPolicy: .clean))
                        .with(testTimeoutConfiguration: testTimeoutConfiguration)
                        .appleTestConfiguration()
                )
                .testEntryConfiguration()
        )
        
        assert {
            try generator.createSimilarlyConfiguredTestEntries()
        } equals: {
            expected
        }
    }
}
