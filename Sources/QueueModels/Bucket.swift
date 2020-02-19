import BuildArtifacts
import Extensions
import Foundation
import Models
import PluginSupport
import SimulatorPoolModels
import RunnerModels

public struct Bucket: Codable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let bucketId: BucketId
    public let buildArtifacts: BuildArtifacts
    public let developerDir: DeveloperDir
    public let pluginLocations: Set<PluginLocation>
    public let simulatorControlTool: SimulatorControlTool
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testEntries: [TestEntry]
    public let testExecutionBehavior: TestExecutionBehavior
    public let testRunnerTool: TestRunnerTool
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testType: TestType

    public init(
        bucketId: BucketId,
        buildArtifacts: BuildArtifacts,
        developerDir: DeveloperDir,
        pluginLocations: Set<PluginLocation>,
        simulatorControlTool: SimulatorControlTool,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testEntries: [TestEntry],
        testExecutionBehavior: TestExecutionBehavior,
        testRunnerTool: TestRunnerTool,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType
    ) {
        self.bucketId = bucketId
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.pluginLocations = pluginLocations
        self.simulatorControlTool = simulatorControlTool
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testEntries = testEntries
        self.testExecutionBehavior = testExecutionBehavior
        self.testRunnerTool = testRunnerTool
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testType = testType
    }
    
    public var description: String {
        return "<\((type(of: self))) \(bucketId) \(testEntries.count) tests>"
    }
    
    public var debugDescription: String {
        return "<\((type(of: self))) \(bucketId) \(developerDir) \(testType) \(testDestination), \(simulatorControlTool), \(simulatorOperationTimeouts), \(testRunnerTool), \(buildArtifacts), \(pluginLocations), \(testEntries.debugDescription)>"
    }
}
