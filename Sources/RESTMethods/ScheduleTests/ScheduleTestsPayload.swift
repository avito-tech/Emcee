import Foundation
import QueueModels
import ScheduleStrategy

public struct ScheduleTestsPayload: Codable, Equatable {
    public let prioritizedJob: PrioritizedJob
    public let scheduleStrategy: ScheduleStrategy
    public let similarlyConfiguredTestEntries: SimilarlyConfiguredTestEntries

    public init(
        prioritizedJob: PrioritizedJob,
        scheduleStrategy: ScheduleStrategy,
        similarlyConfiguredTestEntries: SimilarlyConfiguredTestEntries
    ) {
        self.prioritizedJob = prioritizedJob
        self.scheduleStrategy = scheduleStrategy
        self.similarlyConfiguredTestEntries = similarlyConfiguredTestEntries
    }
}
