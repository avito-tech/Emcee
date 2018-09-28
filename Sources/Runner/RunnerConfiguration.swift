import EventBus
import Foundation
import Models

/** LocalTestRunConfiguration object required by Runner in order to run tests. */
public struct RunnerConfiguration {
    public let testType: TestType
    public let auxiliaryPaths: AuxiliaryPaths
    public let buildArtifacts: BuildArtifacts
    public let environment: [String: String]
    public let simulatorSettings: SimulatorSettings
    public let maximumAllowedSilenceDuration: TimeInterval?
    public let singleTestMaximumDuration: TimeInterval
    public let testDiagnosticOutput: TestDiagnosticOutput
    
    public init(
        testType: TestType,
        auxiliaryPaths: AuxiliaryPaths,
        buildArtifacts: BuildArtifacts,
        testExecutionBehavior: TestExecutionBehavior,
        simulatorSettings: SimulatorSettings,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testDiagnosticOutput: TestDiagnosticOutput)
    {
        var resultingEnvironment = ProcessInfo.processInfo.environment
        resultingEnvironment["FBCONTROLCORE_FAST_TIMEOUT"] = testTimeoutConfiguration.fbxtestFastTimeout.flatMap { "\($0)" }
        resultingEnvironment["FBCONTROLCORE_REGULAR_TIMEOUT"] = testTimeoutConfiguration.fbxtestRegularTimeout.flatMap { "\($0)" }
        resultingEnvironment["FBCONTROLCORE_SLOW_TIMEOUT"] = testTimeoutConfiguration.fbxtestSlowTimeout.flatMap { "\($0)" }
        resultingEnvironment["FB_BUNDLE_READY_TIMEOUT"] = testTimeoutConfiguration.fbxtestBundleReadyTimeout.flatMap { "\($0)" }
        resultingEnvironment["FB_CRASH_CHECK_WAIT_LIMIT"] = testTimeoutConfiguration.fbxtestCrashCheckTimeout.flatMap { "\($0)" }
        
        testExecutionBehavior.environment.forEach { resultingEnvironment[$0] = $1 }
        
        self.testType = testType
        self.auxiliaryPaths = auxiliaryPaths
        self.buildArtifacts = buildArtifacts
        self.environment = resultingEnvironment
        self.simulatorSettings = simulatorSettings
        self.maximumAllowedSilenceDuration = testTimeoutConfiguration.fbxctestSilenceMaximumDuration
        self.singleTestMaximumDuration = testTimeoutConfiguration.singleTestMaximumDuration
        self.testDiagnosticOutput = testDiagnosticOutput
    }
}
