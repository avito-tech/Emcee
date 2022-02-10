import BucketQueue
import CommonTestModels
import Foundation
import QueueModels
import Types

public final class MultipleQueuesStatefulBucketQueue: StatefulBucketQueue {
    private let multipleQueuesContainer: MultipleQueuesContainer
    private let statefulBucketQueueProvider: StatefulBucketQueueProvider
    
    public init(
        multipleQueuesContainer: MultipleQueuesContainer,
        statefulBucketQueueProvider: StatefulBucketQueueProvider
    ) {
        self.multipleQueuesContainer = multipleQueuesContainer
        self.statefulBucketQueueProvider = statefulBucketQueueProvider
    }
    
    public var runningQueueState: RunningQueueState {
        let states = multipleQueuesContainer.allRunningJobQueues().map {
            statefulBucketQueueProvider.createStatefulBucketQueue(
                bucketQueueHolder: $0.bucketQueueHolder
            ).runningQueueState
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
