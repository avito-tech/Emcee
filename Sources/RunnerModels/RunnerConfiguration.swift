import BuildArtifacts
import DeveloperDirModels
import Foundation
import PluginSupport
import SimulatorPoolModels

public struct RunnerConfiguration {
    public let buildArtifacts: BuildArtifacts
    public let developerDir: DeveloperDir
    public let environment: [String: String]
    public let logCapturingMode: LogCapturingMode
    public let userInsertedLibraries: [String]
    public let lostTestProcessingMode: LostTestProcessingMode
    public let persistentMetricsJobId: String?
    public let pluginLocations: Set<PluginLocation>
    public let simulator: Simulator
    public let simulatorSettings: SimulatorSettings
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    
    public init(
        buildArtifacts: BuildArtifacts,
        developerDir: DeveloperDir,
        environment: [String: String],
        logCapturingMode: LogCapturingMode,
        userInsertedLibraries: [String],
        lostTestProcessingMode: LostTestProcessingMode,
        persistentMetricsJobId: String?,
        pluginLocations: Set<PluginLocation>,
        simulator: Simulator,
        simulatorSettings: SimulatorSettings,
        testTimeoutConfiguration: TestTimeoutConfiguration
    ) {
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.environment = environment
        self.logCapturingMode = logCapturingMode
        self.userInsertedLibraries = userInsertedLibraries
        self.lostTestProcessingMode = lostTestProcessingMode
        self.persistentMetricsJobId = persistentMetricsJobId
        self.pluginLocations = pluginLocations
        self.simulator = simulator
        self.simulatorSettings = simulatorSettings
        self.testTimeoutConfiguration = testTimeoutConfiguration
    }
}
