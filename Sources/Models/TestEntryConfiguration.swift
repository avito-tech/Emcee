import Foundation

public struct TestEntryConfiguration: Codable, CustomStringConvertible, Hashable {
    public let buildArtifacts: BuildArtifacts
    public let pluginLocations: Set<PluginLocation>
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testEntry: TestEntry
    public let testExecutionBehavior: TestExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testType: TestType
    public let toolResources: ToolResources
    public let toolchainConfiguration: ToolchainConfiguration

    public init(
        buildArtifacts: BuildArtifacts,
        pluginLocations: Set<PluginLocation>,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testEntry: TestEntry,
        testExecutionBehavior: TestExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType,
        toolResources: ToolResources,
        toolchainConfiguration: ToolchainConfiguration
    ) {
        self.buildArtifacts = buildArtifacts
        self.pluginLocations = pluginLocations
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testEntry = testEntry
        self.testExecutionBehavior = testExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testType = testType
        self.toolResources = toolResources
        self.toolchainConfiguration = toolchainConfiguration
    }
    
    public var description: String {
        return "<\(type(of: self)): \(testEntry) \(testType) \(testDestination) \(buildArtifacts) \(pluginLocations) \(simulatorSettings) \(testExecutionBehavior) \(testTimeoutConfiguration) \(toolResources) \(toolchainConfiguration)>"
    }
}
