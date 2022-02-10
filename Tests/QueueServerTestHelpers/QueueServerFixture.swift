import QueueModels
import QueueServer
import ScheduleStrategy
import SocketModels

public class QueueServerFixture: QueueServer {

    public var isDepleted = false
    public var hasAnyAliveWorker = true
    public var ongoingJobIds = Set<JobId>()
    
    public init() {}
    
    public func start() throws -> Port {
        return 1
    }
    
    public func schedule(
        configuredTestEntries: [ConfiguredTestEntry],
        testSplitter: TestSplitter,
        prioritizedJob: PrioritizedJob
    ) throws {
        ongoingJobIds.insert(prioritizedJob.jobId)
    }
    
    public func queueResults(jobId: JobId) throws -> JobResults {
        return JobResults(jobId: jobId, bucketResults: [])
    }    
}
