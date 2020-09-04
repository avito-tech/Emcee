import BalancingBucketQueue
import Foundation
import XCTest

final class MultipleQueuesContainerTests: XCTestCase {
    lazy var container = MultipleQueuesContainer()
    
    func test___adding_and_querying_running_job_queue() {
        let jobQueue = createJobQueue()
        
        container.add(runningJobQueue: jobQueue)
        
        XCTAssertEqual(
            container.allRunningJobQueues().map { $0.job },
            [jobQueue.job]
        )
        
        XCTAssertEqual(
            container.runningAndDeletedJobQueues().map { $0.job },
            [jobQueue.job]
        )
        
        XCTAssertEqual(
            container.runningJobQueues(jobId: jobQueue.job.jobId).map { $0.job },
            [jobQueue.job]
        )
    }
    
    func test___removing_from_running() {
        let jobQueue = createJobQueue()
        
        container.add(runningJobQueue: jobQueue)
        container.removeRunningJobQueues(jobId: jobQueue.job.jobId)
        
        XCTAssertEqual(
            container.allRunningJobQueues().map { $0.job },
            []
        )
    }
    
    func test___adding_and_querying_deleted_job_queue() {
        let jobQueue = createJobQueue()
        
        container.add(deletedJobQueues: [jobQueue])
        
        XCTAssertEqual(
            container.allDeletedJobQueues().map { $0.job },
            [jobQueue.job]
        )
        
        XCTAssertEqual(
            container.runningAndDeletedJobQueues().map { $0.job },
            [jobQueue.job]
        )
    }
    
    func test___removing_from_deleted() {
        let jobQueue = createJobQueue()
        
        container.add(deletedJobQueues: [jobQueue])
        container.removeFromDeleted(jobId: jobQueue.job.jobId)
        
        XCTAssertEqual(
            container.allDeletedJobQueues().map { $0.job },
            []
        )
    }
    
    func test___tracking_job_groups() {
        let jobGroup = createJobGroup()
        
        container.track(jobGroup: jobGroup)
        
        XCTAssertEqual(
            container.trackedJobGroups(),
            [jobGroup]
        )
        
        container.untrack(jobGroup: jobGroup)
        
        XCTAssertEqual(
            container.trackedJobGroups(),
            []
        )
    }
    
    func test___nested_tracking_od_job_groups() {
        let jobGroup = createJobGroup()
        
        container.track(jobGroup: jobGroup)
        container.track(jobGroup: jobGroup)
        
        XCTAssertEqual(
            container.trackedJobGroups(),
            [jobGroup]
        )
        
        container.untrack(jobGroup: jobGroup)
        
        XCTAssertEqual(
            container.trackedJobGroups(),
            [jobGroup]
        )
        
        container.untrack(jobGroup: jobGroup)
        
        XCTAssertEqual(
            container.trackedJobGroups(),
            []
        )
    }
}
