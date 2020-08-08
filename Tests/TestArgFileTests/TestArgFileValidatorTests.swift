import BuildArtifacts
import BuildArtifactsTestHelpers
import Foundation
import RunnerModels
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestArgFile
import TestHelpers
import XCTest

final class TestArgFileValidatorTests: XCTestCase {
    func test___successful() {
        let testArgFile = TestArgFile(
            entries: [
                TestArgFileEntry(
                    buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
                    developerDir: .current,
                    environment: [:],
                    numberOfRetries: 0,
                    pluginLocations: [],
                    scheduleStrategy: .unsplit,
                    simulatorControlTool: SimulatorControlTool(location: .insideUserLibrary, tool: .simctl),
                    simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                    simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                    testDestination: TestDestinationFixtures.testDestination,
                    testRunnerTool: .xcodebuild(nil),
                    testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
                    testType: .appTest,
                    testsToRun: [],
                    workerCapabilityRequirements: []
                )
            ],
            jobGroupId: "",
            jobGroupPriority: 0,
            jobId: "",
            jobPriority: 0,
            testDestinationConfigurations: []
        )
        
        assertDoesNotThrow {
            try TestArgFileValidator().validate(testArgFile: testArgFile)
        }
    }
    
    func test___insideEmceeTempFolder_and_xcodebuild___incompatible() {
        let testArgFile = TestArgFile(
            entries: [
                TestArgFileEntry(
                    buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
                    developerDir: .current,
                    environment: [:],
                    numberOfRetries: 0,
                    pluginLocations: [],
                    scheduleStrategy: .unsplit,
                    simulatorControlTool: SimulatorControlTool(location: .insideEmceeTempFolder, tool: .simctl),
                    simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                    simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                    testDestination: TestDestinationFixtures.testDestination,
                    testRunnerTool: .xcodebuild(nil),
                    testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
                    testType: .appTest,
                    testsToRun: [],
                    workerCapabilityRequirements: []
                )
            ],
            jobGroupId: "",
            jobGroupPriority: 0,
            jobId: "",
            jobPriority: 0,
            testDestinationConfigurations: []
        )
        
        assertThrows {
            try TestArgFileValidator().validate(testArgFile: testArgFile)
        }
    }
    
    func test___appTest_should_require_appBundle_presense() {
        let testArgFile = TestArgFile(
            entries: [
                TestArgFileEntry(
                    buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: nil, runner: nil, xcTestBundle: "", additionalApplicationBundles: []),
                    developerDir: .current,
                    environment: [:],
                    numberOfRetries: 0,
                    pluginLocations: [],
                    scheduleStrategy: .unsplit,
                    simulatorControlTool: SimulatorControlTool(location: .insideUserLibrary, tool: .simctl),
                    simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                    simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                    testDestination: TestDestinationFixtures.testDestination,
                    testRunnerTool: .xcodebuild(nil),
                    testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
                    testType: .appTest,
                    testsToRun: [],
                    workerCapabilityRequirements: []
                )
            ],
            jobGroupId: "",
            jobGroupPriority: 0,
            jobId: "",
            jobPriority: 0,
            testDestinationConfigurations: []
        )
        
        assertThrows {
            try TestArgFileValidator().validate(testArgFile: testArgFile)
        }
    }
    
    func test___uiTest_should_require_appBundle_presense() {
        let testArgFile = TestArgFile(
            entries: [
                TestArgFileEntry(
                    buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: nil, runner: nil, xcTestBundle: "", additionalApplicationBundles: []),
                    developerDir: .current,
                    environment: [:],
                    numberOfRetries: 0,
                    pluginLocations: [],
                    scheduleStrategy: .unsplit,
                    simulatorControlTool: SimulatorControlTool(location: .insideUserLibrary, tool: .simctl),
                    simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                    simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                    testDestination: TestDestinationFixtures.testDestination,
                    testRunnerTool: .xcodebuild(nil),
                    testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
                    testType: .uiTest,
                    testsToRun: [],
                    workerCapabilityRequirements: []
                )
            ],
            jobGroupId: "",
            jobGroupPriority: 0,
            jobId: "",
            jobPriority: 0,
            testDestinationConfigurations: []
        )
        
        assertThrows {
            try TestArgFileValidator().validate(testArgFile: testArgFile)
        }
    }
    
    func test___uiTest_should_require_runner_presense() {
        let testArgFile = TestArgFile(
            entries: [
                TestArgFileEntry(
                    buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: "", runner: nil, xcTestBundle: "", additionalApplicationBundles: []),
                    developerDir: .current,
                    environment: [:],
                    numberOfRetries: 0,
                    pluginLocations: [],
                    scheduleStrategy: .unsplit,
                    simulatorControlTool: SimulatorControlTool(location: .insideUserLibrary, tool: .simctl),
                    simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                    simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                    testDestination: TestDestinationFixtures.testDestination,
                    testRunnerTool: .xcodebuild(nil),
                    testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
                    testType: .uiTest,
                    testsToRun: [],
                    workerCapabilityRequirements: []
                )
            ],
            jobGroupId: "",
            jobGroupPriority: 0,
            jobId: "",
            jobPriority: 0,
            testDestinationConfigurations: []
        )
        
        assertThrows {
            try TestArgFileValidator().validate(testArgFile: testArgFile)
        }
    }
}

