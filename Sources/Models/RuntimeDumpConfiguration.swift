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

    /** Optional path app test dump*/
    public let applicationTestSupport: RuntimeDumpApplicationTestSupport?
    
    /** Test destination */
    public let testDestination: TestDestination
    
    /** All tests that need to be run */
    public let testsToRun: [TestToRun]

    public init(
        fbxctest: FbxctestLocation,
        xcTestBundle: TestBundleLocation,
        applicationTestSupport: RuntimeDumpApplicationTestSupport?,
        testDestination: TestDestination,
        testsToRun: [TestToRun])
    {
        self.testTimeoutConfiguration = TestTimeoutConfiguration(
            singleTestMaximumDuration: 20,
            fbxctestSilenceMaximumDuration: 20
        )
        self.testRunExecutionBehavior = TestRunExecutionBehavior(
            numberOfSimulators: 1,
            scheduleStrategy: .individual
        )
        self.fbxctest = fbxctest
        self.xcTestBundle = xcTestBundle
        self.applicationTestSupport = applicationTestSupport
        self.testDestination = testDestination
        self.testsToRun = testsToRun
    }
}
