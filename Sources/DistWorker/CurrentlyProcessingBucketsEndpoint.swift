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
    private let logger: ContextualLogger

    public init(
        currentlyBeingProcessedBucketsTracker: CurrentlyBeingProcessedBucketsTracker,
        logger: ContextualLogger
    ) {
        self.currentlyBeingProcessedBucketsTracker = currentlyBeingProcessedBucketsTracker
        self.logger = logger.forType(Self.self)
    }
    
    public func handle(payload: VoidPayload) throws -> CurrentlyProcessingBucketsResponse {
        let bucketIds = Array(currentlyBeingProcessedBucketsTracker.bucketIdsBeingProcessed)
        logger.debug("Processing \(bucketIds.count) buckets")
        return CurrentlyProcessingBucketsResponse(
            bucketIds: bucketIds
        )
    }
}
