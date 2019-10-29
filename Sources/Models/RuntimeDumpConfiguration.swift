import Foundation

public struct RuntimeDumpConfiguration {
    public let developerDir: DeveloperDir
    public let runtimeDumpMode: RuntimeDumpMode
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior
    public let testRunnerTool: TestRunnerTool
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testsToValidate: [TestToRun]
    public let xcTestBundleLocation: TestBundleLocation

    public init(
        developerDir: DeveloperDir,
        runtimeDumpMode: RuntimeDumpMode,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        testRunnerTool: TestRunnerTool,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testsToValidate: [TestToRun],
        xcTestBundleLocation: TestBundleLocation
    ) {
        self.developerDir = developerDir
        self.runtimeDumpMode = runtimeDumpMode
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.testRunnerTool = testRunnerTool
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testsToValidate = testsToValidate
        self.xcTestBundleLocation = xcTestBundleLocation
    }
}
