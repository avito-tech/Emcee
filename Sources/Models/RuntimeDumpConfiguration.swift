import Foundation

public struct RuntimeDumpConfiguration {
    
    /** Timeout values. */
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    
    /** Parameters that determinte how to execute the tests. */
    public let testRunExecutionBehavior: TestRunExecutionBehavior
    
    /** Path to logic test runner. */
    public let testRunnerTool: TestRunnerTool
    
    /** Xctest bundle which contents should be dumped in runtime */
    public let xcTestBundle: XcTestBundle

    /** A helper object to perform runtime dump as an application test run */
    public let applicationTestSupport: RuntimeDumpApplicationTestSupport?
    
    /** Test destination */
    public let testDestination: TestDestination
    
    /** Tests that are expected to run, so runtime dump can validate their presence */
    public let testsToValidate: [TestToRun]
    
    public let developerDir: DeveloperDir

    public init(
        testRunnerTool: TestRunnerTool,
        xcTestBundle: XcTestBundle,
        applicationTestSupport: RuntimeDumpApplicationTestSupport?,
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
        self.xcTestBundle = xcTestBundle
        self.applicationTestSupport = applicationTestSupport
        self.testDestination = testDestination
        self.testsToValidate = testsToValidate
        self.developerDir = developerDir
    }
}
