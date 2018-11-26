import Foundation
import Models
import ScheduleStrategy

public final class BucketSplitInfoFixtures {
    public static func bucketSplitInfoFixture(
        numberOfDestinations: UInt = 1,
        testDestinations: [TestDestination] = [TestDestinationFixtures.testDestination],
        toolResources: ToolResources = ToolResourcesFixtures.fakeToolResources(),
        buildArtifacts: BuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts())
        -> BucketSplitInfo {
        return BucketSplitInfo(
            numberOfDestinations: numberOfDestinations,
            testDestinations: testDestinations,
            toolResources: toolResources,
            buildArtifacts: buildArtifacts)
    }
}
