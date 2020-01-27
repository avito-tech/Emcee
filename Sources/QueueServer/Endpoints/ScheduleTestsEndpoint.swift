import BalancingBucketQueue
import Dispatch
import Foundation
import Models
import RESTMethods
import RESTServer
import UniqueIdentifierGenerator

public final class ScheduleTestsEndpoint: RESTEndpoint {
    private let testsEnqueuer: TestsEnqueuer
    private var enqueuedTestRequestIds = Set<RequestId>()
    private let queue = DispatchQueue(label: "ru.avito.emcee.ScheduleTestsEndpoint.queue")
    private let cleanUpAfter = DispatchTimeInterval.seconds(5 * 60)
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        testsEnqueuer: TestsEnqueuer,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.testsEnqueuer = testsEnqueuer
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func handle(decodedPayload: ScheduleTestsRequest) throws -> ScheduleTestsResponse {
        return queue.sync {
            if !enqueuedTestRequestIds.contains(decodedPayload.requestId) {
                enqueuedTestRequestIds.insert(decodedPayload.requestId)
                
                testsEnqueuer.enqueue(
                    bucketSplitter: decodedPayload.scheduleStrategy.bucketSplitter(
                        uniqueIdentifierGenerator: uniqueIdentifierGenerator
                    ),
                    testEntryConfigurations: decodedPayload.testEntryConfigurations,
                    prioritizedJob: decodedPayload.prioritizedJob
                )
                
                scheduleRemoval(requestId: decodedPayload.requestId)
            }
            return .scheduledTests(requestId: decodedPayload.requestId)
        }
    }
    
    private func scheduleRemoval(requestId: RequestId) {
        queue.asyncAfter(deadline: .now() + cleanUpAfter) { [weak self] in
            guard let strongSelf = self else { return }
            _ = strongSelf.enqueuedTestRequestIds.remove(requestId)
        }
    }
}
