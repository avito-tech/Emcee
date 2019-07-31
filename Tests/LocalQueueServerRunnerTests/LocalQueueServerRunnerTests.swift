import AutomaticTermination
import LocalQueueServerRunner
import Models
import QueueServer
import ScheduleStrategy
import XCTest

final class LocalQueueServerRunnerTests: XCTestCase {
    
    private let automaticTerminationController = AutomaticTerminationControllerFixture(isTerminationAllowed: true)
    private let queueServer = QueueServerFixture()
    private lazy var runner = {
        LocalQueueServerRunner(
            queueServer: queueServer,
            automaticTerminationController: automaticTerminationController,
            queueServerTerminationPolicy: AutomaticTerminationPolicy.stayAlive
        )
    }()
    
    func test__queueServerRunner__stop_work_after_all_worker__have_died() {
        assertNoThrow {
            var completed = false
            queueServer.isDepleted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertFalse(completed)
                self.queueServer.hasAnyAliveWorker = false
                completed = true
            }
            try runner.start()
            XCTAssertTrue(completed)
        }
    }
    
    func test__queueServerRunner__stop_work_after_termination_disallowed() {
        assertNoThrow {
            var completed = false
            queueServer.isDepleted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertFalse(completed)
                self.automaticTerminationController.isTerminationAllowed = false
                completed = true
            }
            try runner.start()
            XCTAssertTrue(completed)
        }
    }
    
    func test__queueServerRunner__stop_work_after_queue_deplete() {
        assertNoThrow {
            var completed = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertFalse(completed)
                self.automaticTerminationController.isTerminationAllowed = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                XCTAssertFalse(completed)
                self.queueServer.isDepleted = true
                completed = true
            }
            try runner.start()
        }
    }
    
    func test__queueServerRunner__stop_work_after_queue_is_empty() {
        assertNoThrow {
            var completed = false
            queueServer.isDepleted = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertFalse(completed)
                self.automaticTerminationController.isTerminationAllowed = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                XCTAssertFalse(completed)
                self.queueServer.ongoingJobIds.insert(JobId(value: UUID().uuidString))
                completed = true
            }
            try runner.start()
            XCTAssertTrue(completed)
        }
    }
    
    private func assertNoThrow(file: StaticString = #file, line: UInt = #line, body: () throws -> ()) {
        do {
            try body()
        } catch let e {
            XCTFail("Unexpectidly caught \(e)", file: file, line: line)
        }
    }
}

class QueueServerFixture: QueueServer {
    
    public var isDepleted = false
    public var hasAnyAliveWorker = true
    public var ongoingJobIds = Set<JobId>()
    
    init() {}
    
    func start() throws -> Int {
        return 1
    }
    
    func schedule(bucketSplitter: BucketSplitter, testEntryConfigurations: [TestEntryConfiguration], prioritizedJob: PrioritizedJob) {
        ongoingJobIds.insert(prioritizedJob.jobId)
    }
    
    func waitForJobToFinish(jobId: JobId) throws -> JobResults {
        return JobResults(jobId: jobId, testingResults: [])
    }
    
}
