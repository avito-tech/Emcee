import ScheduleStrategy
import QueueModels
import SocketModels

public protocol QueueServer {
    func start() throws -> Port
    func schedule(
        configuredTestEntries: [ConfiguredTestEntry],
        testSplitter: TestSplitter,
        prioritizedJob: PrioritizedJob
    ) throws
    func queueResults(jobId: JobId) throws -> JobResults
    var isDepleted: Bool { get }
    var hasAnyAliveWorker: Bool { get }
    var ongoingJobIds: Set<JobId> { get }
}
