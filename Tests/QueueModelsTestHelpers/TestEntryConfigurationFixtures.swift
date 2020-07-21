import BuildArtifacts
import BuildArtifactsTestHelpers
import DeveloperDirModels
import Foundation
import PluginSupport
import QueueModels
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers

public final class TestEntryConfigurationFixtures {
    public var buildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    public var pluginLocations = Set<PluginLocation>()
    public var simulatorSettings = SimulatorSettings(
        simulatorLocalizationSettings: SimulatorLocalizationSettingsFixture().simulatorLocalizationSettings(),
        watchdogSettings: WatchdogSettings(bundleIds: [], timeout: 0)
    )
    public var testDestination = TestDestinationFixtures.testDestination
    public var testEntries = [TestEntry]()
    public var testExecutionBehavior = TestExecutionBehavior(environment: [:], numberOfRetries: 0)
    public var testTimeoutConfiguration = TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0)
    public var testType = TestType.uiTest
    public var developerDir = DeveloperDir.current
    
    public init() {}
    
    public func add(testEntry: TestEntry) -> Self {
        testEntries.append(testEntry)
        return self
    }
    
    public func add(testEntries: [TestEntry]) -> Self {
        self.testEntries.append(contentsOf: testEntries)
        return self
    }
    
    public func with(buildArtifacts: BuildArtifacts) -> Self {
        self.buildArtifacts = buildArtifacts
        return self
    }
    
    public func with(pluginLocations: Set<PluginLocation>) -> Self {
        self.pluginLocations = pluginLocations
        return self
    }
    
    public func with(simulatorSettings: SimulatorSettings) -> Self {
        self.simulatorSettings = simulatorSettings
        return self
    }
    
    public func with(testDestination: TestDestination) -> Self {
        self.testDestination = testDestination
        return self
    }
    
    public func with(testExecutionBehavior: TestExecutionBehavior) -> Self {
        self.testExecutionBehavior = testExecutionBehavior
        return self
    }
    
    public func with(testTimeoutConfiguration: TestTimeoutConfiguration) -> Self {
        self.testTimeoutConfiguration = testTimeoutConfiguration
        return self
    }
    
    public func with(testType: TestType) -> Self {
        self.testType = testType
        return self
    }
    
    public func with(developerDir: DeveloperDir) -> Self {
        self.developerDir = developerDir
        return self
    }
    
    public func testEntryConfigurations() -> [TestEntryConfiguration] {
        return testEntries.map { testEntry in
            TestEntryConfiguration(
                buildArtifacts: buildArtifacts,
                developerDir: developerDir,
                pluginLocations: pluginLocations,
                simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: simulatorSettings,
                testDestination: testDestination,
                testEntry: testEntry,
                testExecutionBehavior: testExecutionBehavior,
                testRunnerTool: TestRunnerToolFixtures.fakeFbxctestTool,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testType: testType
            )
        }
    }
}
