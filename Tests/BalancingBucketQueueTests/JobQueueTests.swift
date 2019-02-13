import BucketQueue
import BucketQueueTestHelpers
@testable import BalancingBucketQueue
import Foundation
import Models
import ResultsCollector
import XCTest

final class JobQueueTests: XCTestCase {
    func test___equality() {
        let jobQueue1 = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job1", priority: .medium),
            creationTime: Date(timeIntervalSince1970: 100),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        let jobQueue2 = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job1", priority: .medium),
            creationTime: Date(timeIntervalSince1970: 100),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        
        XCTAssertEqual(jobQueue1, jobQueue2)
    }
    
    func test___comparison() {
        let jobQueue1 = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job1", priority: .medium),
            creationTime: Date(timeIntervalSince1970: 9999),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        let jobQueue2 = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job1", priority: .medium),
            creationTime: Date(timeIntervalSince1970: 100),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        
        XCTAssertLessThan(jobQueue2, jobQueue1)
    }
    
    func test___comparing_with_priority() {
        let jobQueue1 = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job1", priority: .medium),
            creationTime: Date(timeIntervalSince1970: 100),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        let jobQueue2 = JobQueue(
            prioritizedJob: PrioritizedJob(jobId: "job2", priority: .lowest),
            creationTime: Date(timeIntervalSince1970: 100),
            bucketQueue: FakeBucketQueue(),
            resultsCollector: ResultsCollector()
        )
        
        XCTAssertLessThan(jobQueue2, jobQueue1)
    }
}

