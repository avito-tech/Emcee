import BucketQueue
import DistRun
import Foundation
import Models
import ModelsTestHelpers
import RESTMethods
import XCTest

final class BucketProviderTests: XCTestCase {
    let fetchRequest = BucketFetchRequest(workerId: "worker", requestId: "request")
    
    func test__reponse_is_empty_queue__if_queue_is_empty() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .queueIsEmpty)
        let bucketProvider = BucketProviderEndpoint(bucketQueue: bucketQueue)
        
        let response = try bucketProvider.handle(decodedRequest: fetchRequest)
        XCTAssertEqual(response, .queueIsEmpty)
    }
    
    func test__reponse_is_check_again__if_queue_has_dequeued_buckets() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .nothingToDequeueAtTheMoment)
        let bucketProvider = BucketProviderEndpoint(bucketQueue: bucketQueue)
        
        let response = try bucketProvider.handle(decodedRequest: fetchRequest)
        switch response {
        case .checkAgainLater(let checkAfter):
            XCTAssertTrue(checkAfter > 0)
        default: XCTFail("Unexpecred response: \(response)")
        }
    }
    
    func test__reponse_is_worker_blocked__if_worker_is_blocked() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .workerBlocked)
        let bucketProvider = BucketProviderEndpoint(bucketQueue: bucketQueue)
        
        let response = try bucketProvider.handle(decodedRequest: fetchRequest)
        XCTAssertEqual(response, .workerBlocked)
    }
    
    func test__reponse_has_dequeued_bucket__if_queue_has_enqueued_buckets() throws {
        let dequeuedBucket = DequeuedBucket(
            bucket: BucketFixtures.createBucket(
                testEntries: [TestEntry(className: "class", methodName: "test", caseId: nil)]),
            workerId: "worker",
            requestId: "request")
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .dequeuedBucket(dequeuedBucket))
        let bucketProvider = BucketProviderEndpoint(bucketQueue: bucketQueue)
        
        let response = try bucketProvider.handle(decodedRequest: fetchRequest)
        XCTAssertEqual(response, .bucketDequeued(bucket: dequeuedBucket.bucket))
    }
}
