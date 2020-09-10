import BuildArtifacts
import DeveloperDirModels
import Foundation
import PluginSupport
import RunnerModels
import SimulatorPoolModels
import TestArgFile

public struct TestDiscoveryConfiguration {
    public let developerDir: DeveloperDir
    public let pluginLocations: Set<PluginLocation>
    public let testDiscoveryMode: TestDiscoveryMode
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior
    public let testRunnerTool: TestRunnerTool
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testsToValidate: [TestToRun]
    public let xcTestBundleLocation: TestBundleLocation
    public let persistentMetricsJobId: String

    public init(
        developerDir: DeveloperDir,
        pluginLocations: Set<PluginLocation>,
        testDiscoveryMode: TestDiscoveryMode,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        testRunnerTool: TestRunnerTool,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testsToValidate: [TestToRun],
        xcTestBundleLocation: TestBundleLocation,
        persistentMetricsJobId: String
    ) {
        self.developerDir = developerDir
        self.pluginLocations = pluginLocations
        self.testDiscoveryMode = testDiscoveryMode
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.testRunnerTool = testRunnerTool
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testsToValidate = testsToValidate
        self.xcTestBundleLocation = xcTestBundleLocation
        self.persistentMetricsJobId = persistentMetricsJobId
    }
}
