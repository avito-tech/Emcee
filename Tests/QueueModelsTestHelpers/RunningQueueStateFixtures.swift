import Foundation
import QueueModels

public final class RunningQueueStateFixtures {
    public static func runningQueueState(
        enqueuedBucketCount: Int = 24,
        dequeuedBucketCount: Int = 42
    ) -> RunningQueueState {
        return RunningQueueState(
            enqueuedBucketCount: enqueuedBucketCount,
            dequeuedBucketCount: dequeuedBucketCount
        )
    }
}

