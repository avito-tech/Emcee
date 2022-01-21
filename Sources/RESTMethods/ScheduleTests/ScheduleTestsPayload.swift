import Foundation
import LogStreamingModels
import QueueModels
import ScheduleStrategy

public struct ScheduleTestsPayload: Codable, Equatable {
    public let clientDetails: ClientDetails
    public let prioritizedJob: PrioritizedJob
    public let scheduleStrategy: ScheduleStrategy
    public let testEntryConfigurations: [TestEntryConfiguration]

    public init(
        clientDetails: ClientDetails,
        prioritizedJob: PrioritizedJob,
        scheduleStrategy: ScheduleStrategy,
        testEntryConfigurations: [TestEntryConfiguration]
    ) {
        self.clientDetails = clientDetails
        self.prioritizedJob = prioritizedJob
        self.scheduleStrategy = scheduleStrategy
        self.testEntryConfigurations = testEntryConfigurations
    }
}
