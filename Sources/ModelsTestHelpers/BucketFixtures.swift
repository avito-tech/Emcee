import Foundation
import Models

public final class BucketFixtures {
    public static func createBucket(testEntries: [TestEntry]) -> Bucket {
        return Bucket(
            testEntries: testEntries,
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: ToolResourcesFixtures.fakeToolResources(),
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts())
    }
}
