import BuildArtifacts
import BuildArtifactsTestHelpers
import Foundation
import QueueModels
import RunnerModels
import LoggingSetup
import MetricsExtensions
import ScheduleStrategy
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestArgFile
import TestHelpers
import XCTest

final class TestArgFileValidatorTests: XCTestCase {
    func test___successful() {
        let testArgFile = createTestArgFile(
            entries: [
                TestArgFileEntry(
                    buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
                    developerDir: .current,
                    environment: [:],
                    numberOfRetries: 0,
                    pluginLocations: [],
                    scheduleStrategy: unsplitScheduleStrategy,
                    simulatorControlTool: SimulatorControlTool(location: .insideUserLibrary, tool: .simctl),
                    simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                    simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                    testDestination: TestDestinationFixtures.testDestination,
                    testRunnerTool: .xcodebuild,
                    testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
                    testsToRun: [],
                    workerCapabilityRequirements: []
                )
            ]
        )
        
        assertDoesNotThrow {
            try TestArgFileValidator().validate(testArgFile: testArgFile)
        }
    }
    
    func test___insideEmceeTempFolder_and_xcodebuild___incompatible() {
        let testArgFile = createTestArgFile(
            entries: [
                TestArgFileEntry(
                    buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
                    developerDir: .current,
                    environment: [:],
                    numberOfRetries: 0,
                    pluginLocations: [],
                    scheduleStrategy: unsplitScheduleStrategy,
                    simulatorControlTool: SimulatorControlTool(location: .insideEmceeTempFolder, tool: .simctl),
                    simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                    simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                    testDestination: TestDestinationFixtures.testDestination,
                    testRunnerTool: .xcodebuild,
                    testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
                    testsToRun: [],
                    workerCapabilityRequirements: []
                )
            ]
        )
        
        assertThrows {
            try TestArgFileValidator().validate(testArgFile: testArgFile)
        }
    }
    
    private func createTestArgFile(entries: [TestArgFileEntry]) -> TestArgFile {
        TestArgFile(
            entries: entries,
            prioritizedJob: PrioritizedJob(
                analyticsConfiguration: AnalyticsConfiguration(),
                jobGroupId: "",
                jobGroupPriority: 0,
                jobId: "",
                jobPriority: 0
            ),
            testDestinationConfigurations: []
        )
    }
    
    private lazy var unsplitScheduleStrategy = ScheduleStrategy(testSplitterType: .unsplit)
}

