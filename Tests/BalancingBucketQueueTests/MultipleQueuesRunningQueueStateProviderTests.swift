import BalancingBucketQueue
import BucketQueue
import BucketQueueTestHelpers
import MetricsExtensions
import RunnerModels
import QueueModels
import XCTest

final class MultipleQueuesRunningQueueStateProviderTests: XCTestCase {
    lazy var container = MultipleQueuesContainer()
    lazy var stateProvider = MultipleQueuesRunningQueueStateProvider(multipleQueuesContainer: container)
    
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
        container.add(
            runningJobQueue: createJobQueue(
                runningQueueState: RunningQueueState(
                    enqueuedBucketCount: 50,
                    enqueuedTests: [TestName(className: "Enqueued", methodName: "test")],
                    dequeuedBucketCount: 25,
                    dequeuedTests: ["worker": [TestName(className: "Dequeued", methodName: "test")]]
                ),
                jobId: "job"
            )
        )
        
        XCTAssertEqual(
            stateProvider.runningQueueState,
            RunningQueueState(
                enqueuedBucketCount: 50,
                enqueuedTests: [TestName(className: "Enqueued", methodName: "test")],
                dequeuedBucketCount: 25,
                dequeuedTests: ["worker": [TestName(className: "Dequeued", methodName: "test")]]
            )
        )
    }
    
    func test___multiple_jobs() {
        container.add(
            runningJobQueue: createJobQueue(
                runningQueueState: RunningQueueState(
                    enqueuedBucketCount: 11,
                    enqueuedTests: [TestName(className: "EnqueuedByJob1", methodName: "test")],
                    dequeuedBucketCount: 44,
                    dequeuedTests: ["worker1": [TestName(className: "DequeuedByJob1", methodName: "test")]]
                ),
                jobId: "job1"
            )
        )
        
        container.add(
            runningJobQueue: createJobQueue(
                runningQueueState: RunningQueueState(
                    enqueuedBucketCount: 22,
                    enqueuedTests: [TestName(className: "EnqueuedByJob2", methodName: "test")],
                    dequeuedBucketCount: 55,
                    dequeuedTests: ["worker2": [TestName(className: "DequeuedByJob2", methodName: "test")]]
                ),
                jobId: "job2"
            )
        )
        
        
        XCTAssertEqual(
            stateProvider.runningQueueState,
            RunningQueueState(
                enqueuedBucketCount: 33,
                enqueuedTests: [
                    TestName(className: "EnqueuedByJob1", methodName: "test"),
                    TestName(className: "EnqueuedByJob2", methodName: "test"),
                ],
                dequeuedBucketCount: 99,
                dequeuedTests: [
                    "worker1": [TestName(className: "DequeuedByJob1", methodName: "test")],
                    "worker2": [TestName(className: "DequeuedByJob2", methodName: "test")],
                ]
            )
        )
    }
    
    private func createJobQueue(
        runningQueueState: RunningQueueState,
        jobId: JobId
    ) -> JobQueue {
        let bucketQueue = FakeBucketQueue()
        bucketQueue.runningQueueState = runningQueueState
        
        return JobQueue(
            analyticsConfiguration: AnalyticsConfiguration(),
            bucketQueue: bucketQueue,
            job: Job(creationTime: Date(), jobId: jobId, priority: .medium),
            jobGroup: JobGroup(creationTime: Date(), jobGroupId: JobGroupId("group_" + jobId.value), priority: .medium),
            resultsCollector: ResultsCollector(),
            persistentMetricsJobId: ""
        )
    }
}

