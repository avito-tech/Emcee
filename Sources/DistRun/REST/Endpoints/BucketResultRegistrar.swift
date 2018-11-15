import Dispatch
import EventBus
import Foundation
import Logging
import Models
import RESTMethods

public final class BucketResultRegistrar: RESTEndpoint {
    public typealias T = BucketResultRequest
    
    private let bucketQueue: BucketQueue
    private let eventBus: EventBus
    private let resultsCollector: ResultsCollector

    public init(bucketQueue: BucketQueue, eventBus: EventBus, resultsCollector: ResultsCollector) {
        self.bucketQueue = bucketQueue
        self.eventBus = eventBus
        self.resultsCollector = resultsCollector
    }

    public func handle(decodedRequest: BucketResultRequest) throws -> RESTResponse {
        try bucketQueue.accept(
            testingResult: decodedRequest.testingResult,
            requestId: decodedRequest.requestId,
            workerId: decodedRequest.workerId)
        
        resultsCollector.append(testingResult: decodedRequest.testingResult)
        eventBus.post(event: .didObtainTestingResult(decodedRequest.testingResult))
        
        BucketQueueStateLogger(state: bucketQueue.state).logQueueSize()
        
        return .bucketResultAccepted(bucketId: decodedRequest.testingResult.bucketId)
    }
}
