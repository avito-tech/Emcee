import BalancingBucketQueue
import Foundation
import Models
import RESTMethods

public final class ScheduleTestsEndpoint: RESTEndpoint {
    private let testsEnqueuer: TestsEnqueuer

    public init(testsEnqueuer: TestsEnqueuer) {
        self.testsEnqueuer = testsEnqueuer
    }
    
    public func handle(decodedRequest: ScheduleTestsRequest) throws -> ScheduleTestsResponse {
        testsEnqueuer.enqueue(
            testEntryConfigurations: decodedRequest.testEntryConfigurations,
            jobId: decodedRequest.jobId
        )
        return .scheduledTests
    }
}
