import EventBus
import Foundation
import Models
import ResourceLocationResolver

public struct RunnerConfiguration {
    public let testType: TestType
    public let testRunnerTool: TestRunnerTool
    public let buildArtifacts: BuildArtifacts
    public let environment: [String: String]
    public let simulatorSettings: SimulatorSettings
    public let maximumAllowedSilenceDuration: TimeInterval?
    public let singleTestMaximumDuration: TimeInterval
    
    public init(
        testType: TestType,
        testRunnerTool: TestRunnerTool,
        buildArtifacts: BuildArtifacts,
        environment: [String: String],
        simulatorSettings: SimulatorSettings,
        testTimeoutConfiguration: TestTimeoutConfiguration
    ) {
        var environment = environment
        environment["FBCONTROLCORE_FAST_TIMEOUT"] = testTimeoutConfiguration.fbxtestFastTimeout.flatMap { "\($0)" }
        environment["FBCONTROLCORE_REGULAR_TIMEOUT"] = testTimeoutConfiguration.fbxtestRegularTimeout.flatMap { "\($0)" }
        environment["FBCONTROLCORE_SLOW_TIMEOUT"] = testTimeoutConfiguration.fbxtestSlowTimeout.flatMap { "\($0)" }
        environment["FB_BUNDLE_READY_TIMEOUT"] = testTimeoutConfiguration.fbxtestBundleReadyTimeout.flatMap { "\($0)" }
        environment["FB_CRASH_CHECK_WAIT_LIMIT"] = testTimeoutConfiguration.fbxtestCrashCheckTimeout.flatMap { "\($0)" }
        
        self.testType = testType
        self.testRunnerTool = testRunnerTool
        self.buildArtifacts = buildArtifacts
        self.environment = environment
        self.simulatorSettings = simulatorSettings
        self.maximumAllowedSilenceDuration = testTimeoutConfiguration.fbxctestSilenceMaximumDuration
        self.singleTestMaximumDuration = testTimeoutConfiguration.singleTestMaximumDuration
    }
}
