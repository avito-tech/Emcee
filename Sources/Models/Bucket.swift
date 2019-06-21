import Extensions
import Foundation

public final class Bucket: Codable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let bucketId: BucketId
    public let testEntries: [TestEntry]
    public let buildArtifacts: BuildArtifacts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior
    public let toolResources: ToolResources
    public let testType: TestType

    public init(
        bucketId: BucketId,
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        toolResources: ToolResources,
        testType: TestType)
    {
        self.bucketId = bucketId
        self.testEntries = testEntries
        self.buildArtifacts = buildArtifacts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.toolResources = toolResources
        self.testType = testType
    }
    
    public var description: String {
        return "<\((type(of: self))) \(bucketId), \(testEntries.count) tests>"
    }
    
    public var debugDescription: String {
        return "<\((type(of: self))) \(bucketId) \(testType) \(testDestination), \(toolResources), \(buildArtifacts), \(testEntries.debugDescription)>"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(bucketId)
        hasher.combine(testEntries)
        hasher.combine(buildArtifacts)
        hasher.combine(simulatorSettings)
        hasher.combine(testDestination)
        hasher.combine(testExecutionBehavior)
        hasher.combine(toolResources)
        hasher.combine(testType)
    }
    
    public static func == (left: Bucket, right: Bucket) -> Bool {
        return left.bucketId == right.bucketId
        && left.testEntries == right.testEntries
        && left.buildArtifacts == right.buildArtifacts
        && left.simulatorSettings == right.simulatorSettings
        && left.testDestination == right.testDestination
        && left.testExecutionBehavior == right.testExecutionBehavior
        && left.toolResources == right.toolResources
        && left.testType == right.testType
    }
}
