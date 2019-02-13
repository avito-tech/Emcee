import BalancingBucketQueue
import Dispatch
import Foundation
import Models
import RESTMethods

public final class ScheduleTestsEndpoint: RESTEndpoint {
    private let testsEnqueuer: TestsEnqueuer
    private var enqueuedTestRequestIds = Set<String>()
    private let queue = DispatchQueue(label: "ru.avito.emcee.ScheduleTestsEndpoint.queue")
    private let cleanUpAfter = DispatchTimeInterval.seconds(5 * 60)

    public init(testsEnqueuer: TestsEnqueuer) {
        self.testsEnqueuer = testsEnqueuer
    }
    
    public func handle(decodedRequest: ScheduleTestsRequest) throws -> ScheduleTestsResponse {
        return queue.sync {
            if !enqueuedTestRequestIds.contains(decodedRequest.requestId) {
                enqueuedTestRequestIds.insert(decodedRequest.requestId)
                
                testsEnqueuer.enqueue(
                    testEntryConfigurations: decodedRequest.testEntryConfigurations,
                    prioritizedJob: decodedRequest.prioritizedJob
                )
                
                scheduleRemoval(requestId: decodedRequest.requestId)
            }
            return .scheduledTests(requestId: decodedRequest.requestId)
        }
    }
    
    private func scheduleRemoval(requestId: String) {
        queue.asyncAfter(deadline: .now() + cleanUpAfter) { [weak self] in
            guard let strongSelf = self else { return }
            _ = strongSelf.enqueuedTestRequestIds.remove(requestId)
        }
    }
}
