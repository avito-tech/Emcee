import Foundation

public struct RuntimeDumpConfiguration {
    
    /** Timeout values. */
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    
    /** Parameters that determinte how to execute the tests. */
    public let testRunExecutionBehavior: TestRunExecutionBehavior
    
    /** Path to logic test runner. */
    public let testRunnerTool: TestRunnerTool
    
    /** Xctest bundle which contents should be dumped in runtime */
    public let xcTestBundleLocation: TestBundleLocation

    public let runtimeDumpMode: RuntimeDumpMode

    /** Test destination */
    public let testDestination: TestDestination
    
    /** Tests that are expected to run, so runtime dump can validate their presence */
    public let testsToValidate: [TestToRun]
    
    public let developerDir: DeveloperDir

    public init(
        testRunnerTool: TestRunnerTool,
        xcTestBundleLocation: TestBundleLocation,
        runtimeDumpMode: RuntimeDumpMode,
        testDestination: TestDestination,
        testsToValidate: [TestToRun],
        developerDir: DeveloperDir
    ) {
        self.testTimeoutConfiguration = TestTimeoutConfiguration(
            singleTestMaximumDuration: 20,
            testRunnerMaximumSilenceDuration: 20
        )
        self.testRunExecutionBehavior = TestRunExecutionBehavior(
            numberOfSimulators: 1
        )
        self.testRunnerTool = testRunnerTool
        self.xcTestBundleLocation = xcTestBundleLocation
        self.runtimeDumpMode = runtimeDumpMode
        self.testDestination = testDestination
        self.testsToValidate = testsToValidate
        self.developerDir = developerDir
    }
}
