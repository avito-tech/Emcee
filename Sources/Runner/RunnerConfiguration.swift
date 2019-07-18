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
    public let maximumAllowedSilenceDuration: TimeInterval
    public let singleTestMaximumDuration: TimeInterval
    
    public init(
        testType: TestType,
        testRunnerTool: TestRunnerTool,
        buildArtifacts: BuildArtifacts,
        environment: [String: String],
        simulatorSettings: SimulatorSettings,
        testTimeoutConfiguration: TestTimeoutConfiguration
    ) {
        self.testType = testType
        self.testRunnerTool = testRunnerTool
        self.buildArtifacts = buildArtifacts
        self.environment = environment
        self.simulatorSettings = simulatorSettings
        self.maximumAllowedSilenceDuration = testTimeoutConfiguration.testRunnerMaximumSilenceDuration
        self.singleTestMaximumDuration = testTimeoutConfiguration.singleTestMaximumDuration
    }
}
