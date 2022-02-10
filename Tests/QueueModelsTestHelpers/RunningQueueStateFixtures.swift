import CommonTestModels
import Foundation
import QueueModels
import Types

public final class RunningQueueStateFixtures {
    public static func runningQueueState(
        enqueuedBucketCount: Int = 1,
        enqueuedTests: [TestName] = [
            TestName(className: "EnqueuedClass", methodName: "test1"),
            TestName(className: "EnqueuedClass", methodName: "test2")
        ],
        dequeuedBucketCount: Int = 1,
        dequeuedTests: MapWithCollection<WorkerId, TestName> = [
            "workerId": [
                TestName(className: "DequeuedClass", methodName: "test1"),
                TestName(className: "DequeuedClass", methodName: "test2")
            ]
        ]
    ) -> RunningQueueState {
        return RunningQueueState(
            enqueuedBucketCount: enqueuedBucketCount,
            enqueuedTests: enqueuedTests,
            dequeuedBucketCount: dequeuedBucketCount,
            dequeuedTests: dequeuedTests
        )
    }
}

