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
    
    public func handle(decodedRequest: ScheduleTestsRequest) throws -> ScheduleTestsResponse {
        return queue.sync {
            if !enqueuedTestRequestIds.contains(decodedRequest.requestId) {
                enqueuedTestRequestIds.insert(decodedRequest.requestId)
                
                testsEnqueuer.enqueue(
                    bucketSplitter: decodedRequest.scheduleStrategy.bucketSplitter(
                        uniqueIdentifierGenerator: uniqueIdentifierGenerator
                    ),
                    testEntryConfigurations: decodedRequest.testEntryConfigurations,
                    prioritizedJob: decodedRequest.prioritizedJob
                )
                
                scheduleRemoval(requestId: decodedRequest.requestId)
            }
            return .scheduledTests(requestId: decodedRequest.requestId)
        }
    }
    
    private func scheduleRemoval(requestId: RequestId) {
        queue.asyncAfter(deadline: .now() + cleanUpAfter) { [weak self] in
            guard let strongSelf = self else { return }
            _ = strongSelf.enqueuedTestRequestIds.remove(requestId)
        }
    }
}
