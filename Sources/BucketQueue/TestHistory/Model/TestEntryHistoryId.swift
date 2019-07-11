import Foundation
import Models

public final class TestEntryHistoryId: Hashable {
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
    
    public convenience init(testEntry: TestEntry, bucket: Bucket) {
        self.init(
            testEntry: testEntry,
            testDestination: bucket.testDestination,
            toolResources: bucket.toolResources,
            buildArtifacts: bucket.buildArtifacts,
            bucketId: bucket.bucketId
        )
    }
    
    public static func ==(left: TestEntryHistoryId, right: TestEntryHistoryId) -> Bool {
        return left.testEntry == right.testEntry
            && left.testDestination == right.testDestination
            && left.toolResources == right.toolResources
            && left.buildArtifacts == right.buildArtifacts
            && left.bucketId == right.bucketId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(testEntry)
        hasher.combine(testDestination)
        hasher.combine(toolResources)
        hasher.combine(buildArtifacts)
        hasher.combine(bucketId)
    }
}
