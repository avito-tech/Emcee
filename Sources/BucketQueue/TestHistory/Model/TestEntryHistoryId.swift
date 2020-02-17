import BuildArtifacts
import Foundation
import Models
import QueueModels

public struct TestEntryHistoryId: Hashable {
    public let testEntry: TestEntry
    public let testDestination: TestDestination
    public let toolResources: ToolResources
    public let buildArtifacts: BuildArtifacts
    public let bucketId: BucketId
    
    public init(
        testEntry: TestEntry,
        testDestination: TestDestination,
        toolResources: ToolResources,
        buildArtifacts: BuildArtifacts,
        bucketId: BucketId
    ) {
        self.testEntry = testEntry
        self.testDestination = testDestination
        self.toolResources = toolResources
        self.buildArtifacts = buildArtifacts
        self.bucketId = bucketId
    }
    
    public init(testEntry: TestEntry, bucket: Bucket) {
        self.init(
            testEntry: testEntry,
            testDestination: bucket.testDestination,
            toolResources: bucket.toolResources,
            buildArtifacts: bucket.buildArtifacts,
            bucketId: bucket.bucketId
        )
    }
}
