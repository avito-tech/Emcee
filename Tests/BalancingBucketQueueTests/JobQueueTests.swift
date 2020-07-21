import BucketQueue
import BucketQueueTestHelpers
@testable import BalancingBucketQueue
import Foundation
import QueueModels
import XCTest

final class JobQueueTests: XCTestCase {
    private let commonJobGroup = createJobGroup()
    
    func test___high_priority_queue_should_have_preeminence_over_lower_priority_queue() {
        let highestPriorityJobQueue = createJobQueue(
            job: createJob(priority: .highest),
            jobGroup: commonJobGroup
        )
        let lowestPriorityJobQueue = createJobQueue(
            job: createJob(priority: .lowest),
            jobGroup: commonJobGroup
        )
        
        XCTAssertEqual(
            highestPriorityJobQueue.executionOrder(relativeTo: lowestPriorityJobQueue),
            .before
        )
    }
    
    func test___earlier_created_queue_should_have_preeminence_over_later_created_queue() {
        let earlierCreatedJobQueue = createJobQueue(
            job: createJob(creationTime: Date(timeIntervalSince1970: 100))
        )
        let laterCreatedJobQueue = createJobQueue(
            job: createJob(creationTime: Date(timeIntervalSince1970: 200))
        )

        XCTAssertEqual(
            earlierCreatedJobQueue.executionOrder(relativeTo: laterCreatedJobQueue),
            .before
        )
    }
    
    func test___later_created_queue_with_higher_priority_should_have_preeminence_over_earlier_created_queue_with_lower_priority() {
        let highestPriorityLaterCreatedJobQueue = createJobQueue(
            job: createJob(creationTime: Date(timeIntervalSince1970: 500), priority: .highest),
            jobGroup: commonJobGroup
        )
        let lowestPriorityEarlierCreatedJobQueue = createJobQueue(
            job: createJob(creationTime: Date(timeIntervalSince1970: 100), priority: .lowest),
            jobGroup: commonJobGroup
        )

        XCTAssertEqual(
            highestPriorityLaterCreatedJobQueue.executionOrder(relativeTo: lowestPriorityEarlierCreatedJobQueue),
            .before
        )
    }
    
    func test___earlier_created_group_has_preeminence_over_later_created_group() {
        let jobQueue1 = createJobQueue(
            job: createJob(creationTime: Date(timeIntervalSince1970: 500)),
            jobGroup: createJobGroup(creationTime: Date(timeIntervalSince1970: 100))
        )
        let jobQueue2 = createJobQueue(
            job: createJob(creationTime: Date(timeIntervalSince1970: 100)),
            jobGroup: createJobGroup(creationTime: Date(timeIntervalSince1970: 500))
        )
        
        XCTAssertEqual(
            jobQueue1.executionOrder(relativeTo: jobQueue2),
            .before
        )
    }
}

