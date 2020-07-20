import DistWorker
import Foundation
import Models
import QueueModels
import RequestSender
import XCTest

final class CurrentlyProcessingBucketsEndpointTests: XCTestCase {
    let bucketId = BucketId(value: "bucket")
    let currentlyBeingProcessedBucketsTracker = DefaultCurrentlyBeingProcessedBucketsTracker()
    lazy var endpoint = CurrentlyProcessingBucketsEndpoint(
        currentlyBeingProcessedBucketsTracker: currentlyBeingProcessedBucketsTracker
    )
    
    func test() throws {
        currentlyBeingProcessedBucketsTracker.willProcess(bucketId: bucketId)
        XCTAssertEqual(
            try endpoint.handle(payload: VoidPayload()).bucketIds,
            [bucketId]
        )
        
        currentlyBeingProcessedBucketsTracker.didProcess(bucketId: bucketId)
        XCTAssertEqual(
            try endpoint.handle(payload: VoidPayload()).bucketIds,
            []
        )
    }
}
