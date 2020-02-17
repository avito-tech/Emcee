import BuildArtifacts
import Extensions
import Foundation
import Models
import PluginSupport

public struct Bucket: Codable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let bucketId: BucketId
    public let buildArtifacts: BuildArtifacts
    public let developerDir: DeveloperDir
    public let pluginLocations: Set<PluginLocation>
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testEntries: [TestEntry]
    public let testExecutionBehavior: TestExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testType: TestType
    public let toolResources: ToolResources

    public init(
        bucketId: BucketId,
        buildArtifacts: BuildArtifacts,
        developerDir: DeveloperDir,
        pluginLocations: Set<PluginLocation>,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testEntries: [TestEntry],
        testExecutionBehavior: TestExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType,
        toolResources: ToolResources
    ) {
        self.bucketId = bucketId
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.pluginLocations = pluginLocations
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testEntries = testEntries
        self.testExecutionBehavior = testExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testType = testType
        self.toolResources = toolResources
    }
    
    public var description: String {
        return "<\((type(of: self))) \(bucketId) \(testEntries.count) tests>"
    }
    
    public var debugDescription: String {
        return "<\((type(of: self))) \(bucketId) \(developerDir) \(testType) \(testDestination), \(toolResources), \(buildArtifacts), \(pluginLocations), \(testEntries.debugDescription)>"
    }
}
