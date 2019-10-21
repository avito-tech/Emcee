import EventBus
import Foundation
import Models
import ResourceLocationResolver

public struct RunnerConfiguration {
    public let buildArtifacts: BuildArtifacts
    public let environment: [String: String]
    public let maximumAllowedSilenceDuration: TimeInterval
    public let simulatorSettings: SimulatorSettings
    public let singleTestMaximumDuration: TimeInterval
    public let testRunnerTool: TestRunnerTool
    public let testType: TestType
    
    public init(
        buildArtifacts: BuildArtifacts,
        environment: [String: String],
        simulatorSettings: SimulatorSettings,
        testRunnerTool: TestRunnerTool,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType
    ) {
        self.buildArtifacts = buildArtifacts
        self.environment = environment
        self.maximumAllowedSilenceDuration = testTimeoutConfiguration.testRunnerMaximumSilenceDuration
        self.simulatorSettings = simulatorSettings
        self.singleTestMaximumDuration = testTimeoutConfiguration.singleTestMaximumDuration
        self.testRunnerTool = testRunnerTool
        self.testType = testType
    }
}
