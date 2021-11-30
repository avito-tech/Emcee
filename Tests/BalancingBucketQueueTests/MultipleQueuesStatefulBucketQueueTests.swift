import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import DateProviderTestHelpers
import MetricsExtensions
import RunnerModels
import QueueModels
import QueueModelsTestHelpers
import XCTest

final class MultipleQueuesStatefulBucketQueueTests: XCTestCase {
    lazy var container = MultipleQueuesContainer()
    lazy var dateProvider = DateProviderFixture()
    lazy var statefulBucketQueueProvider = FakeStatefulBucketQueueProvider()
    lazy var stateProvider = MultipleQueuesStatefulBucketQueue(
        multipleQueuesContainer: container,
        statefulBucketQueueProvider: statefulBucketQueueProvider
    )
    
    func test___empty_container() {
        XCTAssertEqual(
            stateProvider.runningQueueState,
            RunningQueueState(
                enqueuedBucketCount: 0,
                enqueuedTests: [],
                dequeuedBucketCount: 0,
                dequeuedTests: [:]
            )
        )
    }
    
    func test___single_job() {
        let runningQueueState = RunningQueueState(
            enqueuedBucketCount: 50,
            enqueuedTests: [TestName(className: "Enqueued", methodName: "test")],
            dequeuedBucketCount: 25,
            dequeuedTests: ["worker": [TestName(className: "Dequeued", methodName: "test")]]
        )
        statefulBucketQueueProvider.fakeStatefulBucketQueue.runningQueueState = runningQueueState
        container.add(runningJobQueue: BalancingBucketQueueTests.createJobQueue())
        
        XCTAssertEqual(
            stateProvider.runningQueueState,
            runningQueueState
        )
    }
    
    func test___multiple_jobs() {
        var states: [RunningQueueState] = [
            RunningQueueState(
                enqueuedBucketCount: 50,
                enqueuedTests: [
                    TestName(className: "Enqueued1", methodName: "test1"),
                ],
                dequeuedBucketCount: 25,
                dequeuedTests: [
                    "worker1": [
                        TestName(className: "Dequeued1", methodName: "test1"),
                    ],
                ]
            ),
            RunningQueueState(
                enqueuedBucketCount: 10,
                enqueuedTests: [
                    TestName(className: "Enqueued2", methodName: "test2"),
                ],
                dequeuedBucketCount: 7,
                dequeuedTests: [
                    "worker2": [
                        TestName(className: "Dequeued2", methodName: "test2"),
                    ],
                ]
            ),
        ]
        
        statefulBucketQueueProvider.fakeStatefulBucketQueue.resultProvider = {
            let result = states[0]
            states.removeFirst()
            return result
        }
        
        container.add(runningJobQueue: BalancingBucketQueueTests.createJobQueue())
        container.add(runningJobQueue: BalancingBucketQueueTests.createJobQueue())
        
        XCTAssertEqual(
            stateProvider.runningQueueState,
            RunningQueueState(
                enqueuedBucketCount: 60,
                enqueuedTests: [
                    TestName(className: "Enqueued1", methodName: "test1"),
                    TestName(className: "Enqueued2", methodName: "test2"),
                ],
                dequeuedBucketCount: 32,
                dequeuedTests: [
                    "worker1": [
                        TestName(className: "Dequeued1", methodName: "test1"),
                    ],
                    "worker2": [
                        TestName(className: "Dequeued2", methodName: "test2"),
                    ],
                ]
            )
        )
    }
}

