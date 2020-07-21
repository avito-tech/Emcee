import Foundation
import QueueModels
import ScheduleStrategy

public struct ScheduleTestsRequest: Codable, Equatable {
    public let requestId: RequestId
    public let prioritizedJob: PrioritizedJob
    public let scheduleStrategy: ScheduleStrategyType
    public let testEntryConfigurations: [TestEntryConfiguration]

    public init(
        requestId: RequestId,
        prioritizedJob: PrioritizedJob,
        scheduleStrategy: ScheduleStrategyType,
        testEntryConfigurations: [TestEntryConfiguration]
    ) {
        self.requestId = requestId
        self.prioritizedJob = prioritizedJob
        self.scheduleStrategy = scheduleStrategy
        self.testEntryConfigurations = testEntryConfigurations
    }
}
