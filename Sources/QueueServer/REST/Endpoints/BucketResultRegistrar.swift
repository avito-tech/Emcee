import BucketQueue
import Dispatch
import EventBus
import Foundation
import Logging
import Models
import RESTMethods
import ResultsCollector
import WorkerAlivenessTracker

public final class BucketResultRegistrar: RESTEndpoint {
    private let eventBus: EventBus
    private let resultsCollector: ResultsCollector
    private let statefulBucketResultAccepter: BucketResultAccepter & QueueStateProvider
    private let workerAlivenessTracker: WorkerAlivenessTracker

    public init(
        eventBus: EventBus,
        resultsCollector: ResultsCollector,
        statefulBucketResultAccepter: BucketResultAccepter & QueueStateProvider,
        workerAlivenessTracker: WorkerAlivenessTracker)
    {
        self.eventBus = eventBus
        self.resultsCollector = resultsCollector
        self.statefulBucketResultAccepter = statefulBucketResultAccepter
        self.workerAlivenessTracker = workerAlivenessTracker
    }

    public func handle(decodedRequest: PushBucketResultRequest) throws -> BucketResultAcceptResponse {
        do {
            let acceptResult = try statefulBucketResultAccepter.accept(
                testingResult: decodedRequest.testingResult,
                requestId: decodedRequest.requestId,
                workerId: decodedRequest.workerId
            )
            
            resultsCollector.append(testingResult: acceptResult.testingResultToCollect)
            eventBus.post(event: .didObtainTestingResult(acceptResult.testingResultToCollect))
            BucketQueueStateLogger(state: statefulBucketResultAccepter.state).logQueueSize()
            
            return .bucketResultAccepted(bucketId: decodedRequest.testingResult.bucketId)
        } catch {
            workerAlivenessTracker.blockWorker(workerId: decodedRequest.workerId)
            throw error
        }
    }
}
