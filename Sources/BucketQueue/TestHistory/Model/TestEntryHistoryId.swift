import Foundation
import Models

public final class TestEntryHistoryId: Hashable {
    public let testEntry: TestEntry
    public let testDestination: TestDestination
    public let toolResources: ToolResources
    public let buildArtifacts: BuildArtifacts
    
    public init(
        testEntry: TestEntry,
        testDestination: TestDestination,
        toolResources: ToolResources,
        buildArtifacts: BuildArtifacts)
    {
        self.testEntry = testEntry
        self.testDestination = testDestination
        self.toolResources = toolResources
        self.buildArtifacts = buildArtifacts
    }
    
    public convenience init(testEntry: TestEntry, bucket: Bucket) {
        self.init(
            testEntry: testEntry,
            testDestination: bucket.testDestination,
            toolResources: bucket.toolResources,
            buildArtifacts: bucket.buildArtifacts
        )
    }
    
    public static func ==(left: TestEntryHistoryId, right: TestEntryHistoryId) -> Bool {
        return left.testEntry == right.testEntry
            && left.testDestination == right.testDestination
            && left.toolResources == right.toolResources
            && left.buildArtifacts == right.buildArtifacts
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(testEntry)
        hasher.combine(testDestination)
        hasher.combine(toolResources)
        hasher.combine(buildArtifacts)
    }
}
