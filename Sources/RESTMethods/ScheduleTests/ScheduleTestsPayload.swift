import Foundation
import QueueModels
import ScheduleStrategy

public struct ScheduleTestsPayload: Codable, Equatable {
    public let prioritizedJob: PrioritizedJob
    public let scheduleStrategy: ScheduleStrategy
    public let testEntryConfigurations: [TestEntryConfiguration]

    public init(
        prioritizedJob: PrioritizedJob,
        scheduleStrategy: ScheduleStrategy,
        testEntryConfigurations: [TestEntryConfiguration]
    ) {
        self.prioritizedJob = prioritizedJob
        self.scheduleStrategy = scheduleStrategy
        self.testEntryConfigurations = testEntryConfigurations
    }
}
