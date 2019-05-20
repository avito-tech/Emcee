import Foundation

public final class AppTestDumpData {
    /** Path to hosting application*/
    public let appBundle: AppBundleLocation

    /** Path to Fbsimctl to run simulator*/
    public let fbsimctl: FbsimctlLocation

    public init(
        appBundle: AppBundleLocation,
        fbsimctl: FbsimctlLocation
    ) {
        self.appBundle = appBundle
        self.fbsimctl = fbsimctl
    }
}

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
    public let appTestDumpData: AppTestDumpData?
    
    /** Test destination */
    public let testDestination: TestDestination
    
    /** All tests that need to be run */
    public let testsToRun: [TestToRun]

    public init(
        fbxctest: FbxctestLocation,
        xcTestBundle: TestBundleLocation,
        appTestDumpData: AppTestDumpData?,
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
        self.appTestDumpData = appTestDumpData
        self.testDestination = testDestination
        self.testsToRun = testsToRun
    }
}
