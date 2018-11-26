import Foundation

public struct RuntimeDumpConfiguration {
    
    /** Timeout values. */
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    
    /** Parameters that determinte how to execute the tests. */
    public let testRunExecutionBehavior: TestRunExecutionBehavior
    
    /** Path to logic test runner. */
    public let fbxctest: FbxctestLocation
    
    /** Path to xctest bundle which contents should be dumped in runtime */
    public let xcTestBundle: TestBundleLocation
    
    /** Some settings that should be applied to the test environment prior running the tests. */
    public let simulatorSettings: SimulatorSettings
    
    /** Test destination */
    public let testDestination: TestDestination
    
    /** All tests that need to be run */
    public let testsToRun: [TestToRun]

    public init(
        fbxctest: FbxctestLocation,
        xcTestBundle: TestBundleLocation,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testsToRun: [TestToRun])
    {
        self.testTimeoutConfiguration = TestTimeoutConfiguration(
            singleTestMaximumDuration: 20,
            fbxctestSilenceMaximumDuration: 20)
        self.testRunExecutionBehavior = TestRunExecutionBehavior(
            numberOfRetries: 0,
            numberOfSimulators: 1,
            environment: [:],
            scheduleStrategy: .individual)
        self.fbxctest = fbxctest
        self.xcTestBundle = xcTestBundle
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testsToRun = testsToRun
    }
}
