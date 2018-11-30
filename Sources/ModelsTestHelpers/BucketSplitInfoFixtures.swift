import Foundation
import Models
import ScheduleStrategy

public final class BucketSplitInfoFixtures {
    public static func bucketSplitInfoFixture(
        numberOfDestinations: UInt = 1,
        toolResources: ToolResources = ToolResourcesFixtures.fakeToolResources()
        )
        -> BucketSplitInfo {
        return BucketSplitInfo(
            numberOfDestinations: numberOfDestinations,
            toolResources: toolResources
        )
    }
}
