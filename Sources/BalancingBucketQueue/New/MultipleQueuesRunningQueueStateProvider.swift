import BucketQueue
import Foundation
import QueueModels
import RunnerModels
import Types

public final class MultipleQueuesRunningQueueStateProvider: RunningQueueStateProvider {
    private let multipleQueuesContainer: MultipleQueuesContainer
    
    public init(multipleQueuesContainer: MultipleQueuesContainer) {
        self.multipleQueuesContainer = multipleQueuesContainer
    }
    
    public var runningQueueState: RunningQueueState {
        let states = multipleQueuesContainer.allRunningJobQueues().map {
            $0.bucketQueue.runningQueueState
        }
        var dequeuedTests = MapWithCollection<WorkerId, TestName>()
        for state in states {
            dequeuedTests.extend(state.dequeuedTests)
        }
        
        return RunningQueueState(
            enqueuedBucketCount: states.reduce(into: 0, { $0 += $1.enqueuedBucketCount }),
            enqueuedTests: states.flatMap { $0.enqueuedTests },
            dequeuedBucketCount: states.reduce(into: 0, { $0 += $1.dequeuedBucketCount }),
            dequeuedTests: dequeuedTests
        )
    }
}
