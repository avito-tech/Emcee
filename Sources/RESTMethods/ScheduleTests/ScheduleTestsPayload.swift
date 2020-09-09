import Foundation
import QueueModels
import ScheduleStrategy

public struct ScheduleTestsPayload: Codable, Equatable {
    public let prioritizedJob: PrioritizedJob
    public let scheduleStrategy: ScheduleStrategyType
    public let testEntryConfigurations: [TestEntryConfiguration]

    public init(
        prioritizedJob: PrioritizedJob,
        scheduleStrategy: ScheduleStrategyType,
        testEntryConfigurations: [TestEntryConfiguration]
    ) {
        self.prioritizedJob = prioritizedJob
        self.scheduleStrategy = scheduleStrategy
        self.testEntryConfigurations = testEntryConfigurations
    }
}
