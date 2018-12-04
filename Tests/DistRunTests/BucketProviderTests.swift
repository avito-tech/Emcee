import BucketQueue
import DistRun
import Foundation
import Models
import ModelsTestHelpers
import RESTMethods
import WorkerAlivenessTracker
import WorkerAlivenessTrackerTestHelpers
import XCTest

final class BucketProviderTests: XCTestCase {
    let fetchRequest = BucketFetchRequest(workerId: "worker", requestId: "request")
    let alivenessTracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
    
    func test___reponse_is_empty_queue___if_queue_is_empty() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .queueIsEmpty)
        let bucketProvider = BucketProviderEndpoint(bucketQueue: bucketQueue, alivenessTracker: alivenessTracker)
        
        let response = try bucketProvider.handle(decodedRequest: fetchRequest)
        XCTAssertEqual(response, .queueIsEmpty)
    }
    
    func test___reponse_is_check_again___if_queue_has_dequeued_buckets() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .checkAgainLater(checkAfter: 42))
        let bucketProvider = BucketProviderEndpoint(bucketQueue: bucketQueue, alivenessTracker: alivenessTracker)
        
        let response = try bucketProvider.handle(decodedRequest: fetchRequest)
        XCTAssertEqual(response, .checkAgainLater(checkAfter: 42))
    }
    
    func test___reponse_is_worker_blocked___if_worker_is_blocked() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .workerBlocked)
        let bucketProvider = BucketProviderEndpoint(bucketQueue: bucketQueue, alivenessTracker: alivenessTracker)
        
        let response = try bucketProvider.handle(decodedRequest: fetchRequest)
        XCTAssertEqual(response, .workerBlocked)
    }
    
    func test___reponse_has_dequeued_bucket___if_queue_has_enqueued_buckets() throws {
        let dequeuedBucket = DequeuedBucket(
            bucket: BucketFixtures.createBucket(
                testEntries: [TestEntry(className: "class", methodName: "test", caseId: nil)]),
            workerId: "worker",
            requestId: "request")
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .dequeuedBucket(dequeuedBucket))
        let bucketProvider = BucketProviderEndpoint(bucketQueue: bucketQueue, alivenessTracker: alivenessTracker)
        
        let response = try bucketProvider.handle(decodedRequest: fetchRequest)
        XCTAssertEqual(response, .bucketDequeued(bucket: dequeuedBucket.bucket))
    }
    
    func test___when_bucket_is_dequeued___aliveness_tracker_appends_bucket_id() throws {
        let bucket = BucketFixtures.createBucket(
            testEntries: [TestEntry(className: "class", methodName: "test", caseId: nil)]
        )
        let dequeuedBucket = DequeuedBucket(bucket: bucket, workerId: "worker", requestId: "request")
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .dequeuedBucket(dequeuedBucket))
        let bucketProvider = BucketProviderEndpoint(bucketQueue: bucketQueue, alivenessTracker: alivenessTracker)
        
        _ = try bucketProvider.handle(decodedRequest: fetchRequest)
        
        let aliveness = alivenessTracker.alivenessForWorker(workerId: "worker")
        XCTAssertEqual(
            aliveness,
            WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [bucket.bucketId])
        )
    }
}
