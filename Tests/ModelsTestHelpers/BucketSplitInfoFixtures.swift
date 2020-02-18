import Foundation
import Models
import ScheduleStrategy

public final class BucketSplitInfoFixtures {
    public static func bucketSplitInfoFixture(
        numberOfWorkers: UInt = 1
    ) -> BucketSplitInfo {
        return BucketSplitInfo(
            numberOfWorkers: numberOfWorkers
        )
    }
}
