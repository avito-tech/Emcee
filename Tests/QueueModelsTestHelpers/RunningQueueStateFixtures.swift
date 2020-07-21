import Foundation
import QueueModels
import RunnerModels
import Types

public final class RunningQueueStateFixtures {
    public static func runningQueueState(
        enqueuedTests: [TestName] = [
            TestName(className: "EnqueuedClass", methodName: "test1"),
            TestName(className: "EnqueuedClass", methodName: "test2")
        ],
        dequeuedTests: MapWithCollection<WorkerId, TestName> = [
            "workerId": [
                TestName(className: "DequeuedClass", methodName: "test1"),
                TestName(className: "DequeuedClass", methodName: "test2")
            ]
        ]
    ) -> RunningQueueState {
        return RunningQueueState(
            enqueuedTests: enqueuedTests,
            dequeuedTests: dequeuedTests
        )
    }
}

