import Dispatch
import Foundation
import QueueModels
import RESTMethods
import RequestSender
import ScheduleStrategy
import Types

public final class TestSchedulerImpl: TestScheduler {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func scheduleTests(
        prioritizedJob: PrioritizedJob,
        scheduleStrategy: ScheduleStrategyType,
        testEntryConfigurations: [TestEntryConfiguration],
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<Void, Error>) -> ()
    ) {
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
            do {
                let response = try result.dematerialize()
                switch response {
                case .scheduledTests:
                    completion(.success(()))
                }
            } catch {
                completion(.error(error))
            }
        }
    }
}
