import Foundation
import Models

public final class SchedulerBucket: CustomStringConvertible {
    public let bucketId: String
    public let testEntries: [TestEntry]
    public let buildArtifacts: BuildArtifacts
    public let environment: [String: String]
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let toolResources: ToolResources
    
    public var description: String {
        return "<\((type(of: self))) bucketId=\(bucketId)>"
    }

    public init(
        bucketId: String,
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        environment: [String: String],
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        toolResources: ToolResources
        )
    {
        self.bucketId = bucketId
        self.testEntries = testEntries
        self.buildArtifacts = buildArtifacts
        self.environment = environment
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.toolResources = toolResources
    }
    
    public static func from(bucket: Bucket) -> SchedulerBucket {
        return SchedulerBucket(
            bucketId: bucket.bucketId,
            testEntries: bucket.testEntries,
            buildArtifacts: bucket.buildArtifacts,
            environment: bucket.environment,
            simulatorSettings: bucket.simulatorSettings,
            testDestination: bucket.testDestination,
            toolResources: bucket.toolResources
        )
    }
}
