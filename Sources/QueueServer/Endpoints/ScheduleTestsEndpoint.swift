import BalancingBucketQueue
import Dispatch
import Foundation
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer
import UniqueIdentifierGenerator

public final class ScheduleTestsEndpoint: RESTEndpoint {
    private let testsEnqueuer: TestsEnqueuer
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
    
    public func handle(payload: ScheduleTestsPayload) throws -> ScheduleTestsResponse {
        try testsEnqueuer.enqueue(
            bucketSplitter: payload.scheduleStrategy.bucketSplitter(
                uniqueIdentifierGenerator: uniqueIdentifierGenerator
            ),
            testEntryConfigurations: payload.testEntryConfigurations,
            prioritizedJob: payload.prioritizedJob
        )
        return .scheduledTests
    }
}
