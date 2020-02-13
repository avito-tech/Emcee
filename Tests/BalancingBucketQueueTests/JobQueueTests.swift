import BucketQueue
import BucketQueueTestHelpers
@testable import BalancingBucketQueue
import Foundation
import Models
import QueueModels
import ResultsCollector
import XCTest

final class JobQueueTests: XCTestCase {
    func test___high_priority_queue_should_have_preeminence_over_lower_priority_queue() {
        let highestPriorityJobQueue = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job1", priority: .highest),
            creationTime: Date(timeIntervalSince1970: 100),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        let lowestPriorityJobQueue = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job2", priority: .lowest),
            creationTime: Date(timeIntervalSince1970: 100),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        XCTAssertTrue(
            highestPriorityJobQueue.hasPreeminence(overJobQueue: lowestPriorityJobQueue)
        )
    }
    
    func test___earlier_created_queue_should_have_preeminence_over_later_created_queue() {
        let earlierCreatedJobQueue = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job1", priority: .medium),
            creationTime: Date(timeIntervalSince1970: 100),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        let laterCreatedJobQueue = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job2", priority: .medium),
            creationTime: Date(timeIntervalSince1970: 200),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        XCTAssertTrue(
            earlierCreatedJobQueue.hasPreeminence(overJobQueue: laterCreatedJobQueue)
        )
    }
    
    func test___later_created_queue_with_higher_priority_should_have_preeminence_over_earlier_created_queue_with_lower_priority() {
        let highestPriorityLaterCreatedJobQueue = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job1", priority: .highest),
            creationTime: Date(timeIntervalSince1970: 500),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        let lowestPriorityEarlierCreatedJobQueue = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job2", priority: .lowest),
            creationTime: Date(timeIntervalSince1970: 100),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        XCTAssertTrue(
            highestPriorityLaterCreatedJobQueue.hasPreeminence(overJobQueue: lowestPriorityEarlierCreatedJobQueue)
        )
    }
}

