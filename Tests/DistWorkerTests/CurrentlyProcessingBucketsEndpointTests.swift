import CurrentlyBeingProcessedBucketsTracker
import DistWorker
import Foundation
import Models
import RequestSender
import XCTest

final class CurrentlyProcessingBucketsEndpointTests: XCTestCase {
    let bucketId = BucketId(value: "bucket")
    let currentlyBeingProcessedBucketsTracker = CurrentlyBeingProcessedBucketsTracker()
    lazy var endpoint = CurrentlyProcessingBucketsEndpoint(
        currentlyBeingProcessedBucketsTracker: currentlyBeingProcessedBucketsTracker
    )
    
    func test() throws {
        currentlyBeingProcessedBucketsTracker.didFetch(bucketId: bucketId)
        XCTAssertEqual(
            try endpoint.handle(decodedPayload: VoidPayload()).bucketIds,
            [bucketId]
        )
        
        currentlyBeingProcessedBucketsTracker.didSendResults(bucketId: bucketId)
        XCTAssertEqual(
            try endpoint.handle(decodedPayload: VoidPayload()).bucketIds,
            []
        )
    }
}
