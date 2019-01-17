import Foundation
import Models

public final class SchedulerBucket: CustomStringConvertible, Equatable {
    public let bucketId: String
    public let testEntries: [TestEntry]
    public let buildArtifacts: BuildArtifacts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior
    public let toolResources: ToolResources
    
    public var description: String {
        return "<\((type(of: self))) bucketId=\(bucketId)>"
    }

    public init(
        bucketId: String,
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        toolResources: ToolResources
        )
    {
        self.bucketId = bucketId
        self.testEntries = testEntries
        self.buildArtifacts = buildArtifacts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.toolResources = toolResources
    }
    
    public static func from(bucket: Bucket) -> SchedulerBucket {
        return SchedulerBucket(
            bucketId: bucket.bucketId,
            testEntries: bucket.testEntries,
            buildArtifacts: bucket.buildArtifacts,
            simulatorSettings: bucket.simulatorSettings,
            testDestination: bucket.testDestination,
            testExecutionBehavior: bucket.testExecutionBehavior,
            toolResources: bucket.toolResources
        )
    }
    
    public static func == (left: SchedulerBucket, right: SchedulerBucket) -> Bool {
        return left.bucketId == right.bucketId
            && left.testEntries == right.testEntries
            && left.buildArtifacts == right.buildArtifacts
            && left.simulatorSettings == right.simulatorSettings
            && left.testDestination == right.testDestination
            && left.testExecutionBehavior == right.testExecutionBehavior
            && left.toolResources == right.toolResources
    }
}
