import DistWorkerModels
import Foundation
import Logging
import RESTServer
import RequestSender

public final class CurrentlyProcessingBucketsEndpoint: RESTEndpoint {
    public typealias DecodedObjectType = VoidPayload
    public typealias ResponseType = CurrentlyProcessingBucketsResponse
    
    private let currentlyBeingProcessedBucketsTracker: CurrentlyBeingProcessedBucketsTracker

    public init(currentlyBeingProcessedBucketsTracker: CurrentlyBeingProcessedBucketsTracker) {
        self.currentlyBeingProcessedBucketsTracker = currentlyBeingProcessedBucketsTracker
    }
    
    public func handle(
        decodedPayload: VoidPayload
    ) throws -> CurrentlyProcessingBucketsResponse {
        let bucketIds = Array(currentlyBeingProcessedBucketsTracker.bucketIdsBeingProcessed)
        Logger.debug("Processing \(bucketIds.count) buckets")
        return CurrentlyProcessingBucketsResponse(
            bucketIds: bucketIds
        )
    }
}
