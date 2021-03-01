import DistWorkerModels
import Foundation
import EmceeLogging
import RESTInterfaces
import RESTMethods
import RESTServer
import RequestSender

public final class CurrentlyProcessingBucketsEndpoint: RESTEndpoint {
    public typealias PayloadType = VoidPayload
    public typealias ResponseType = CurrentlyProcessingBucketsResponse
    public let path: RESTPath = CurrentlyProcessingBuckets.path
    public let requestIndicatesActivity = false
    
    private let currentlyBeingProcessedBucketsTracker: CurrentlyBeingProcessedBucketsTracker

    public init(currentlyBeingProcessedBucketsTracker: CurrentlyBeingProcessedBucketsTracker) {
        self.currentlyBeingProcessedBucketsTracker = currentlyBeingProcessedBucketsTracker
    }
    
    public func handle(payload: VoidPayload) throws -> CurrentlyProcessingBucketsResponse {
        let bucketIds = Array(currentlyBeingProcessedBucketsTracker.bucketIdsBeingProcessed)
        Logger.debug("Processing \(bucketIds.count) buckets")
        return CurrentlyProcessingBucketsResponse(
            bucketIds: bucketIds
        )
    }
}
