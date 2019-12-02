import EventBus
import Foundation
import Models
import ResourceLocationResolver

public struct RunnerConfiguration {
    public let buildArtifacts: BuildArtifacts
    public let environment: [String: String]
    public let simulatorSettings: SimulatorSettings
    public let testRunnerTool: TestRunnerTool
    public let testTimeoutConfiguration: TestTimeoutConfiguration
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
        self.simulatorSettings = simulatorSettings
        self.testRunnerTool = testRunnerTool
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testType = testType
    }
}
