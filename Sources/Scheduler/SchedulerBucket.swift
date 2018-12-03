import Foundation
import Models

public final class SchedulerBucket: CustomStringConvertible {
    public let bucketId: String
    public let testEntries: [TestEntry]
    public let testDestination: TestDestination
    public let toolResources: ToolResources
    public let buildArtifacts: BuildArtifacts
    public let simulatorSettings: SimulatorSettings
    
    public var description: String {
        return "<\((type(of: self))) bucketId=\(bucketId)>"
    }

    public init(
        bucketId: String,
        testEntries: [TestEntry],
        testDestination: TestDestination,
        toolResources: ToolResources,
        buildArtifacts: BuildArtifacts,
        simulatorSettings: SimulatorSettings
        )
    {
        self.bucketId = bucketId
        self.testEntries = testEntries
        self.testDestination = testDestination
        self.toolResources = toolResources
        self.buildArtifacts = buildArtifacts
        self.simulatorSettings = simulatorSettings
    }
    
    public static func from(bucket: Bucket) -> SchedulerBucket {
        return SchedulerBucket(
            bucketId: bucket.bucketId,
            testEntries: bucket.testEntries,
            testDestination: bucket.testDestination,
            toolResources: bucket.toolResources,
            buildArtifacts: bucket.buildArtifacts,
            simulatorSettings: bucket.simulatorSettings
        )
    }
}
