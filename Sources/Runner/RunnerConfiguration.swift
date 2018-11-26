import EventBus
import Foundation
import Models
import ResourceLocationResolver

/** LocalTestRunConfiguration object required by Runner in order to run tests. */
public struct RunnerConfiguration {
    public let testType: TestType
    public let fbxctest: FbxctestLocation
    public let buildArtifacts: BuildArtifacts
    public let environment: [String: String]
    public let simulatorSettings: SimulatorSettings
    public let maximumAllowedSilenceDuration: TimeInterval?
    public let singleTestMaximumDuration: TimeInterval
    
    public init(
        testType: TestType,
        fbxctest: FbxctestLocation,
        buildArtifacts: BuildArtifacts,
        testRunExecutionBehavior: TestRunExecutionBehavior,
        simulatorSettings: SimulatorSettings,
        testTimeoutConfiguration: TestTimeoutConfiguration)
    {
        var resultingEnvironment = ProcessInfo.processInfo.environment
        resultingEnvironment["FBCONTROLCORE_FAST_TIMEOUT"] = testTimeoutConfiguration.fbxtestFastTimeout.flatMap { "\($0)" }
        resultingEnvironment["FBCONTROLCORE_REGULAR_TIMEOUT"] = testTimeoutConfiguration.fbxtestRegularTimeout.flatMap { "\($0)" }
        resultingEnvironment["FBCONTROLCORE_SLOW_TIMEOUT"] = testTimeoutConfiguration.fbxtestSlowTimeout.flatMap { "\($0)" }
        resultingEnvironment["FB_BUNDLE_READY_TIMEOUT"] = testTimeoutConfiguration.fbxtestBundleReadyTimeout.flatMap { "\($0)" }
        resultingEnvironment["FB_CRASH_CHECK_WAIT_LIMIT"] = testTimeoutConfiguration.fbxtestCrashCheckTimeout.flatMap { "\($0)" }
        
        testRunExecutionBehavior.environment.forEach { resultingEnvironment[$0] = $1 }
        
        self.testType = testType
        self.fbxctest = fbxctest
        self.buildArtifacts = buildArtifacts
        self.environment = resultingEnvironment
        self.simulatorSettings = simulatorSettings
        self.maximumAllowedSilenceDuration = testTimeoutConfiguration.fbxctestSilenceMaximumDuration
        self.singleTestMaximumDuration = testTimeoutConfiguration.singleTestMaximumDuration
    }
}
