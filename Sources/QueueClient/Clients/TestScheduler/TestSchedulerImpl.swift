import Dispatch
import Foundation
import EmceeLogging
import QueueModels
import RESTMethods
import RequestSender
import ScheduleStrategy
import Types

public final class TestSchedulerImpl: TestScheduler {
    private let logger: ContextualLogger
    private let requestSender: RequestSender
    
    public init(
        logger: ContextualLogger,
        requestSender: RequestSender
    ) {
        self.logger = logger
        self.requestSender = requestSender
    }
    
    public func scheduleTests(
        prioritizedJob: PrioritizedJob,
        scheduleStrategy: ScheduleStrategy,
        similarlyConfiguredTestEntries: SimilarlyConfiguredTestEntries,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<Void, Error>) -> ()
    ) {
        logger.trace("Will schedule \(similarlyConfiguredTestEntries.testEntries.count) tests")
        requestSender.sendRequestWithCallback(
            request: ScheduleTestsRequest(
                payload: ScheduleTestsPayload(
                    prioritizedJob: prioritizedJob,
                    scheduleStrategy: scheduleStrategy,
                    similarlyConfiguredTestEntries: similarlyConfiguredTestEntries
                )
            ),
            callbackQueue: callbackQueue
        ) { (result: Either<ScheduleTestsResponse, RequestSenderError>) in
            completion(
                result.mapResult {
                    switch $0 {
                    case .scheduledTests: return ()
                    }
                }
            )
        }
    }
}
