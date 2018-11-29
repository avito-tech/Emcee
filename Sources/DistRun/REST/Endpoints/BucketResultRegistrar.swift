import BucketQueue
import Dispatch
import EventBus
import Foundation
import Logging
import Models
import RESTMethods
import WorkerAlivenessTracker

public final class BucketResultRegistrar: RESTEndpoint {
    public typealias T = BucketResultRequest
    
    private let bucketQueue: BucketQueue
    private let eventBus: EventBus
    private let resultsCollector: ResultsCollector
    private let workerAlivenessTracker: WorkerAlivenessTracker

    public init(
        bucketQueue: BucketQueue,
        eventBus: EventBus,
        resultsCollector: ResultsCollector,
        workerAlivenessTracker: WorkerAlivenessTracker)
    {
        self.bucketQueue = bucketQueue
        self.eventBus = eventBus
        self.resultsCollector = resultsCollector
        self.workerAlivenessTracker = workerAlivenessTracker
    }

    public func handle(decodedRequest: BucketResultRequest) throws -> RESTResponse {
        do {
            let acceptResult = try bucketQueue.accept(
                testingResult: decodedRequest.testingResult,
                requestId: decodedRequest.requestId,
                workerId: decodedRequest.workerId)
            
            resultsCollector.append(testingResult: acceptResult.testingResultToCollect)
            eventBus.post(event: .didObtainTestingResult(acceptResult.testingResultToCollect))
            BucketQueueStateLogger(state: bucketQueue.state).logQueueSize()
            
            return .bucketResultAccepted(bucketId: decodedRequest.testingResult.bucketId)
        } catch {
            workerAlivenessTracker.blockWorker(workerId: decodedRequest.workerId)
            throw error
        }
    }
}
