import Foundation
import Models

public final class ScheduleTestsRequest: Codable {
    public let requestId: RequestId
    public let prioritizedJob: PrioritizedJob
    public let testEntryConfigurations: [TestEntryConfiguration]

    public init(
        requestId: RequestId,
        prioritizedJob: PrioritizedJob,
        testEntryConfigurations: [TestEntryConfiguration])
    {
        self.requestId = requestId
        self.prioritizedJob = prioritizedJob
        self.testEntryConfigurations = testEntryConfigurations
    }
}

extension ScheduleTestsRequest: Equatable {
    public static func ==(left: ScheduleTestsRequest, right: ScheduleTestsRequest) -> Bool {
        return left.requestId == right.requestId
            && left.prioritizedJob == right.prioritizedJob
            && left.testEntryConfigurations == right.testEntryConfigurations
    }
}
