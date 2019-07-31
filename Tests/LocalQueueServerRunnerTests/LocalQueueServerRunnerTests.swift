import AutomaticTermination
import LocalQueueServerRunner
import Models
import QueueServer
import ScheduleStrategy
import XCTest

final class LocalQueueServerRunnerTests: XCTestCase {
    
    private let automaticTerminationController = AutomaticTerminationControllerFixture(isTerminationAllowed: false)
    private let queueServer = QueueServerFixture()
    private lazy var runner = LocalQueueServerRunner(
        queueServer: queueServer,
        automaticTerminationController: automaticTerminationController,
        pollInterval: 0.01,
        queueServerTerminationPolicy: AutomaticTerminationPolicy.stayAlive
    )
    
    let queue = DispatchQueue(label: "runner queue")
    let impactQueue = DispatchQueue(label: "impact queue")
    
    func test___queue_server_runner_should_wait___while_automatic_termination_is_not_allowed() throws {
        let expectation = self.expectation(description: "runner should wait while automatic termination is not allowed and it has alive workers")
        expectation.isInverted = true
        
        queueServer.isDepleted = true
        
        queue.async {
            _ = try? self.runner.start()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test___queue_server_runner_should_wait___while_queue_is_not_depleted() throws {
        let expectation = self.expectation(description: "runner should wait while it has alive workers and queue is not depleted")
        expectation.isInverted = true
        
        automaticTerminationController.isTerminationAllowed = true
        queueServer.isDepleted = false
        queueServer.ongoingJobIds = [JobId(value: "jobid")]
        
        queue.async {
            _ = try? self.runner.start()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test___queue_server_runner_should_wait___while_queue_has_jobs() throws {
        let expectation = self.expectation(description: "runner should wait while it has alive workers and queue has jobs")
        expectation.isInverted = true
        
        automaticTerminationController.isTerminationAllowed = true
        queueServer.isDepleted = true
        queueServer.ongoingJobIds = [JobId(value: "jobid")]
        
        queue.async {
            _ = try? self.runner.start()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test___queue_server_runner_stops___after_all_workers_have_died() throws {
        let expectation = self.expectation(description: "runner should stop when queue has no alive workers")
        
        queue.async {
            _ = try? self.runner.start()
            expectation.fulfill()
        }
        
        impactQueue.asyncAfter(deadline: .now() + 0.1) {
            self.queueServer.hasAnyAliveWorker = false
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    func test___queue_server_runner_stops___after_automatic_termination() throws {
        let expectation = self.expectation(description: "runner should stop when automatic termination controller allows")
        queueServer.isDepleted = true
        
        queue.async {
            _ = try? self.runner.start()
            expectation.fulfill()
        }
        
        impactQueue.asyncAfter(deadline: .now() + 0.1) {
            self.automaticTerminationController.isTerminationAllowed = true
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    func test___queue_server_runner_stops___after_automatic_termination_is_allowed_and_queue_depletes() throws {
        automaticTerminationController.isTerminationAllowed = true
        
        let expectation = self.expectation(description: "runner should stop when automatic termination controller allows and after queue has been depleted")
        
        queue.async {
            _ = try? self.runner.start()
            expectation.fulfill()
        }
        
        impactQueue.asyncAfter(deadline: .now() + 0.1) {
            self.queueServer.isDepleted = true
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    func test___queue_server_runner_stops___after_automatic_termination_is_allowed_and_queue_has_no_jobs_left() throws {
        automaticTerminationController.isTerminationAllowed = true
        queueServer.isDepleted = true
        queueServer.ongoingJobIds.insert(JobId(value: UUID().uuidString))
        
        let expectation = self.expectation(description: "runner should stop when automatic termination controller allows and after queue has no jobs left")
        
        queue.async {
            _ = try? self.runner.start()
            expectation.fulfill()
        }
        
        impactQueue.asyncAfter(deadline: .now() + 0.1) {
            self.queueServer.ongoingJobIds.removeAll()
        }
        
        wait(for: [expectation], timeout: 60.0)
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
