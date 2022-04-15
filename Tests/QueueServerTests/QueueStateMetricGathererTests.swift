import CommonTestModels
import DateProviderTestHelpers
import Foundation
import Graphite
import MetricsRecording
import QueueModels
import QueueServer
import Types
import XCTest

final class QueueStateMetricGathererTests: XCTestCase {
    lazy var dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 100500))
    lazy var queueHost = "queue_host"
    lazy var gatherer = QueueStateMetricGatherer(
        dateProvider: dateProvider,
        queueHost: queueHost,
        version: version
    )
    lazy var version = Version("version")
    
    lazy var jobState1 = JobState(
        jobId: "job1",
        queueState: .running(
            RunningQueueState(
                enqueuedBucketCount: 1,
                enqueuedTests: [
                    TestName(className: "Job1_enqueuedTest", methodName: "test"),
                ],
                dequeuedBucketCount: 0,
                dequeuedTests: [:]
            )
        )
    )
    lazy var jobState2 = JobState(
        jobId: "job2",
        queueState: .running(
            RunningQueueState(
                enqueuedBucketCount: 0,
                enqueuedTests: [],
                dequeuedBucketCount: 1,
                dequeuedTests: [
                    "job2_worker1": [
                        TestName(className: "Job2_dequeuedClass", methodName: "test"),
                    ]
                ]
            )
        )
    )
    
    func test_metrics() {
        let metrics = Set(
            gatherer.metrics(
                jobStates: [
                    jobState1,
                    jobState2,
                ],
                runningQueueState: RunningQueueState(
                    enqueuedBucketCount: 24,
                    enqueuedTests: [
                        TestName(className: "SomeTest1", methodName: "test"),
                        TestName(className: "SomeTest2", methodName: "test"),
                        TestName(className: "SomeTest3", methodName: "test"),
                    ],
                    dequeuedBucketCount: 42,
                    dequeuedTests: MapWithCollection(
                        [
                            "someworker1": [
                                TestName(className: "SomeTestOnSomeWorker1", methodName: "test"),
                            ],
                            "someworker2": [
                                TestName(className: "SomeTestOnSomeWorker2", methodName: "test1"),
                                TestName(className: "SomeTestOnSomeWorker2", methodName: "test2"),
                            ],
                            "someworker3": [
                                TestName(className: "SomeTestOnSomeWorker3", methodName: "test"),
                            ],
                        ]
                    )
                )
            )
        )
        
        let expectedMetrics: [GraphiteMetric] = [
            JobStateDequeuedBucketsMetric(queueHost: queueHost, jobId: jobState1.jobId.value, numberOfDequeuedBuckets: 0, version: version, timestamp: dateProvider.currentDate()),
            JobStateEnqueuedBucketsMetric(queueHost: queueHost, jobId: jobState1.jobId.value, numberOfEnqueuedBuckets: 1, version: version, timestamp: dateProvider.currentDate()),
            
            JobStateDequeuedBucketsMetric(queueHost: queueHost, jobId: jobState2.jobId.value, numberOfDequeuedBuckets: 1, version: version, timestamp: dateProvider.currentDate()),
            JobStateEnqueuedBucketsMetric(queueHost: queueHost, jobId: jobState2.jobId.value, numberOfEnqueuedBuckets: 0, version: version, timestamp: dateProvider.currentDate()),
            
            QueueStateDequeuedBucketsMetric(queueHost: queueHost, numberOfDequeuedBuckets: 42, version: version, timestamp: dateProvider.currentDate()),
            QueueStateDequeuedTestsMetric(queueHost: queueHost, numberOfDequeuedTests: 4, version: version, timestamp: dateProvider.currentDate()),
            QueueStateEnqueuedBucketsMetric(queueHost: queueHost, numberOfEnqueuedBuckets: 24, version: version, timestamp: dateProvider.currentDate()),
            QueueStateEnqueuedTestsMetric(queueHost: queueHost, numberOfEnqueuedTests: 3, version: version, timestamp: dateProvider.currentDate()),
            
            JobCountMetric(queueHost: queueHost, version: version, jobCount: 2, timestamp: dateProvider.currentDate())
        ]
        
        XCTAssertEqual(
            metrics,
            Set(expectedMetrics)
        )
    }
}

