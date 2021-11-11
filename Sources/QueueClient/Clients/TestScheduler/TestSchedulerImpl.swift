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
        testEntryConfigurations: [TestEntryConfiguration],
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<Void, Error>) -> ()
    ) {
        logger.debug("Will schedule \(testEntryConfigurations.count) tests")
        requestSender.sendRequestWithCallback(
            request: ScheduleTestsRequest(
                payload: ScheduleTestsPayload(
                    prioritizedJob: prioritizedJob,
                    scheduleStrategy: scheduleStrategy,
                    testEntryConfigurations: testEntryConfigurations
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
