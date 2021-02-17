import BalancingBucketQueue
import BucketQueueTestHelpers
import DateProviderTestHelpers
import Foundation
import MetricsExtensions
import MetricsTestHelpers
import QueueModels
import TestHelpers
import XCTest

final class MultipleQueuesJobManipulatorTests: XCTestCase {
    private lazy var container = MultipleQueuesContainer()
    private lazy var manipulator = MultipleQueuesJobManipulator(
        dateProvider: DateProviderFixture(),
        specificMetricRecorderProvider: NoOpSpecificMetricRecorderProvider(),
        multipleQueuesContainer: container,
        emceeVersion: Version(value: "version")
    )
    
    func test___deleting_non_existing_job___throws() {
        assertThrows {
            try manipulator.delete(jobId: "jobId")
        }
    }
    
    func test___deleting_existing_job() {
        let bucketQueue = FakeBucketQueue()
        
        container.add(runningJobQueue: createJobQueue(bucketQueue: bucketQueue, job: createJob(jobId: "jobId")))
        
        assertDoesNotThrow {
            try manipulator.delete(jobId: "jobId")
        }
        
        XCTAssertTrue(bucketQueue.removedAllEnqueuedBuckets)
        
        XCTAssertEqual(
            container.allDeletedJobQueues().map { $0.job.jobId },
            [JobId("jobId")]
        )
        XCTAssertEqual(
            container.trackedJobGroups().map { $0.jobGroupId },
            []
        )
    }
}
