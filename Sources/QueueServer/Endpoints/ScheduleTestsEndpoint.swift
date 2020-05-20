import BalancingBucketQueue
import Dispatch
import Foundation
import Models
import RESTInterfaces
import RESTMethods
import RESTServer
import UniqueIdentifierGenerator

public final class ScheduleTestsEndpoint: RESTEndpoint {
    private let testsEnqueuer: TestsEnqueuer
    private var enqueuedTestRequestIds = Set<RequestId>()
    private let queue = DispatchQueue(label: "ru.avito.emcee.ScheduleTestsEndpoint.queue")
    private let cleanUpAfter = DispatchTimeInterval.seconds(5 * 60)
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    public let path: RESTPath = RESTMethod.scheduleTests
    public let requestIndicatesActivity = true
    
    public init(
        testsEnqueuer: TestsEnqueuer,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.testsEnqueuer = testsEnqueuer
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func handle(payload: ScheduleTestsRequest) throws -> ScheduleTestsResponse {
        return queue.sync {
            if !enqueuedTestRequestIds.contains(payload.requestId) {
                enqueuedTestRequestIds.insert(payload.requestId)
                
                testsEnqueuer.enqueue(
                    bucketSplitter: payload.scheduleStrategy.bucketSplitter(
                        uniqueIdentifierGenerator: uniqueIdentifierGenerator
                    ),
                    testEntryConfigurations: payload.testEntryConfigurations,
                    prioritizedJob: payload.prioritizedJob
                )
                
                scheduleRemoval(requestId: payload.requestId)
            }
            return .scheduledTests(requestId: payload.requestId)
        }
    }
    
    private func scheduleRemoval(requestId: RequestId) {
        queue.asyncAfter(deadline: .now() + cleanUpAfter) { [weak self] in
            guard let strongSelf = self else { return }
            _ = strongSelf.enqueuedTestRequestIds.remove(requestId)
        }
    }
}
