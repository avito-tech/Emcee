import Foundation
import Models

public final class ScheduleTestsRequest: Codable {
    public let requestId: RequestId
    public let prioritizedJob: PrioritizedJob
    public let scheduleStrategy: ScheduleStrategyType
    public let testEntryConfigurations: [TestEntryConfiguration]

    public init(
        requestId: RequestId,
        prioritizedJob: PrioritizedJob,
        scheduleStrategy: ScheduleStrategyType,
        testEntryConfigurations: [TestEntryConfiguration])
    {
        self.requestId = requestId
        self.prioritizedJob = prioritizedJob
        self.scheduleStrategy = scheduleStrategy
        self.testEntryConfigurations = testEntryConfigurations
    }
}

extension ScheduleTestsRequest: Equatable {
    public static func ==(left: ScheduleTestsRequest, right: ScheduleTestsRequest) -> Bool {
        return left.requestId == right.requestId
            && left.prioritizedJob == right.prioritizedJob
            && left.scheduleStrategy == right.scheduleStrategy
            && left.testEntryConfigurations == right.testEntryConfigurations
    }
}
