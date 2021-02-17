import BuildArtifacts
import BuildArtifactsTestHelpers
import EmceeLib
import Foundation
import MetricsExtensions
import QueueModelsTestHelpers
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestArgFile
import TestDiscovery
import TestHelpers
import XCTest

final class TestEntryConfigurationGeneratorTests: XCTestCase {
    lazy var argFileTestToRun1 = TestName(className: "classFromArgs", methodName: "test1")
    lazy var argFileTestToRun2 = TestName(className: "classFromArgs", methodName: "test2")
    lazy var buildArtifacts = BuildArtifactsFixtures.withLocalPaths(
        appBundle: "1",
        runner: "1",
        xcTestBundle: "1",
        additionalApplicationBundles: ["1", "2"]
    )
    lazy var argFileDestination1 = assertDoesNotThrow { try TestDestination(deviceType: UUID().uuidString, runtime: "10.1") }
    lazy var argFileDestination2 = assertDoesNotThrow { try TestDestination(deviceType: UUID().uuidString, runtime: "10.2") }
    lazy var simulatorSettings = SimulatorSettingsFixtures().simulatorSettings()
    lazy var testTimeoutConfiguration = TestTimeoutConfiguration(singleTestMaximumDuration: 10, testRunnerMaximumSilenceDuration: 20)
    lazy var analyticsConfiguration = AnalyticsConfiguration()

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
                scheduleStrategy: .unsplit,
                simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: simulatorSettings,
                testDestination: argFileDestination1,
                testRunnerTool: TestRunnerToolFixtures.fakeFbxctestTool,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testType: .uiTest,
                testsToRun: [.testName(argFileTestToRun1)],
                workerCapabilityRequirements: []
            ),
            persistentMetricsJobId: ""
        )
        
        let configurations = generator.createTestEntryConfigurations()
        
        let expectedConfigurations = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1"))
            .with(buildArtifacts: buildArtifacts)
            .with(simulatorSettings: simulatorSettings)
            .with(testDestination: argFileDestination1)
            .with(testTimeoutConfiguration: testTimeoutConfiguration)
            .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
            .with(testType: .uiTest)
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
                scheduleStrategy: .unsplit,
                simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: simulatorSettings,
                testDestination: argFileDestination1,
                testRunnerTool: TestRunnerToolFixtures.fakeFbxctestTool,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testType: .uiTest,
                testsToRun: [.testName(argFileTestToRun1), .testName(argFileTestToRun1)],
                workerCapabilityRequirements: []
            ),
            persistentMetricsJobId: ""
        )
        
        let expectedTestEntryConfigurations =
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1"))
                .with(buildArtifacts: buildArtifacts)
                .with(simulatorSettings: simulatorSettings)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
                .with(testDestination: argFileDestination1)
                .with(testTimeoutConfiguration: testTimeoutConfiguration)
                .with(testType: .uiTest)
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
                scheduleStrategy: .unsplit,
                simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: simulatorSettings,
                testDestination: argFileDestination1,
                testRunnerTool: TestRunnerToolFixtures.fakeFbxctestTool,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testType: .uiTest,
                testsToRun: [.allDiscoveredTests],
                workerCapabilityRequirements: []
            ),
            persistentMetricsJobId: ""
        )
        
        let expectedConfigurations = [
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1"))
                .with(buildArtifacts: buildArtifacts)
                .with(testDestination: argFileDestination1)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
                .with(testTimeoutConfiguration: testTimeoutConfiguration)
                .with(testType: .uiTest)
                .testEntryConfigurations(),
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test2"))
                .with(buildArtifacts: buildArtifacts)
                .with(testDestination: argFileDestination1)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
                .with(testTimeoutConfiguration: testTimeoutConfiguration)
                .with(testType: .uiTest)
                .testEntryConfigurations()
            ].flatMap { $0 }
        
        XCTAssertEqual(
            Set(generator.createTestEntryConfigurations()),
            Set(expectedConfigurations)
        )
    }
}
