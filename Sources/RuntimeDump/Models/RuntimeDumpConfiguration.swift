import Foundation
import Models

public struct RuntimeDumpConfiguration {
    public let developerDir: DeveloperDir
    public let pluginLocations: Set<PluginLocation>
    public let runtimeDumpMode: RuntimeDumpMode
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior
    public let testRunnerTool: TestRunnerTool
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testsToValidate: [TestToRun]
    public let xcTestBundleLocation: TestBundleLocation

    public init(
        developerDir: DeveloperDir,
        pluginLocations: Set<PluginLocation>,
        runtimeDumpMode: RuntimeDumpMode,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        testRunnerTool: TestRunnerTool,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testsToValidate: [TestToRun],
        xcTestBundleLocation: TestBundleLocation
    ) {
        self.developerDir = developerDir
        self.pluginLocations = pluginLocations
        self.runtimeDumpMode = runtimeDumpMode
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.testRunnerTool = testRunnerTool
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testsToValidate = testsToValidate
        self.xcTestBundleLocation = xcTestBundleLocation
    }
}
