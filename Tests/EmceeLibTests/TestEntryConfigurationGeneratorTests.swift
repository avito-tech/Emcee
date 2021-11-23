import BuildArtifacts
import BuildArtifactsTestHelpers
import EmceeLib
import EmceeLogging
import Foundation
import MetricsExtensions
import QueueModelsTestHelpers
import RunnerModels
import RunnerTestHelpers
import ScheduleStrategy
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestArgFile
import TestDiscovery
import TestHelpers
import XCTest

final class TestEntryConfigurationGeneratorTests: XCTestCase {
    lazy var argFileTestToRun1 = TestName(className: "classFromArgs", methodName: "test1")
    lazy var argFileTestToRun2 = TestName(className: "classFromArgs", methodName: "test2")
    lazy var buildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    lazy var argFileDestination = assertDoesNotThrow { try TestDestination(deviceType: UUID().uuidString, runtime: "10.1") }
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
    
    func test() {
        let generator = TestEntryConfigurationGenerator(
            analyticsConfiguration: analyticsConfiguration,
            validatedEntries: validatedEntries,
            testArgFileEntry: TestArgFileEntry(
                buildArtifacts: buildArtifacts,
                developerDir: .current,
                environment: [:],
                numberOfRetries: 10,
                pluginLocations: [],
                scheduleStrategy: unsplitScheduleStrategy,
                simulatorControlTool: SimulatorControlToolFixtures.simctlTool,
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: simulatorSettings,
                testDestination: argFileDestination,
                testRunnerTool: .xcodebuild,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testsToRun: [.testName(argFileTestToRun1)],
                workerCapabilityRequirements: []
            ),
            logger: .noOp
        )
        
        let configurations = generator.createTestEntryConfigurations()
        
        let expectedConfigurations = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1"))
            .with(buildArtifacts: buildArtifacts)
            .with(simulatorSettings: simulatorSettings)
            .with(testDestination: argFileDestination)
            .with(testTimeoutConfiguration: testTimeoutConfiguration)
            .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
            .testEntryConfigurations()
        
        XCTAssertEqual(Set(configurations), Set(expectedConfigurations))
    }
    
    func test_repeated_items() {
        let generator = TestEntryConfigurationGenerator(
            analyticsConfiguration: analyticsConfiguration,
            validatedEntries: validatedEntries,
            testArgFileEntry: TestArgFileEntry(
                buildArtifacts: buildArtifacts,
                developerDir: .current,
                environment: [:],
                numberOfRetries: 10,
                pluginLocations: [],
                scheduleStrategy: unsplitScheduleStrategy,
                simulatorControlTool: SimulatorControlToolFixtures.simctlTool,
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: simulatorSettings,
                testDestination: argFileDestination,
                testRunnerTool: .xcodebuild,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testsToRun: [.testName(argFileTestToRun1), .testName(argFileTestToRun1)],
                workerCapabilityRequirements: []
            ),
            logger: .noOp
        )
        
        let expectedTestEntryConfigurations =
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1"))
                .with(buildArtifacts: buildArtifacts)
                .with(simulatorSettings: simulatorSettings)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
                .with(testDestination: argFileDestination)
                .with(testTimeoutConfiguration: testTimeoutConfiguration)
                .testEntryConfigurations()
        
        XCTAssertEqual(
            generator.createTestEntryConfigurations(),
            expectedTestEntryConfigurations + expectedTestEntryConfigurations
        )
    }
    
    func test__all_available_tests() {
        let generator = TestEntryConfigurationGenerator(
            analyticsConfiguration: analyticsConfiguration,
            validatedEntries: validatedEntries,
            testArgFileEntry: TestArgFileEntry(
                buildArtifacts: buildArtifacts,
                developerDir: .current,
                environment: [:],
                numberOfRetries: 10,
                pluginLocations: [],
                scheduleStrategy: unsplitScheduleStrategy,
                simulatorControlTool: SimulatorControlToolFixtures.simctlTool,
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: simulatorSettings,
                testDestination: argFileDestination,
                testRunnerTool: .xcodebuild,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testsToRun: [.allDiscoveredTests],
                workerCapabilityRequirements: []
            ),
            logger: .noOp
        )
        
        let expectedConfigurations = [
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1"))
                .with(buildArtifacts: buildArtifacts)
                .with(testDestination: argFileDestination)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
                .with(testTimeoutConfiguration: testTimeoutConfiguration)
                .testEntryConfigurations(),
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test2"))
                .with(buildArtifacts: buildArtifacts)
                .with(testDestination: argFileDestination)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
                .with(testTimeoutConfiguration: testTimeoutConfiguration)
                .testEntryConfigurations()
            ].flatMap { $0 }
        
        XCTAssertEqual(
            Set(generator.createTestEntryConfigurations()),
            Set(expectedConfigurations)
        )
    }
}
