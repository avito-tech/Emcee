import ScheduleStrategy
import Models

public protocol QueueServer {
    func start() throws -> Int
    func schedule(
        bucketSplitter: BucketSplitter,
        testEntryConfigurations: [TestEntryConfiguration],
        prioritizedJob: PrioritizedJob
    )
    func waitForJobToFinish(jobId: JobId) throws -> JobResults
    var isDepleted: Bool { get }
    var hasAnyAliveWorker: Bool { get }
    var ongoingJobIds: Set<JobId> { get }
}
