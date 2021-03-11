import AutomaticTermination
import AutomaticTerminationTestHelpers
import QueueServer
import QueueServerTestHelpers
import ScheduleStrategy
import XCTest

final class QueueServerTerminationWaiterImplTests: XCTestCase {
    
    private let automaticTerminationController = AutomaticTerminationControllerFixture(isTerminationAllowed: false)
    private let queueServer = QueueServerFixture()
    private let waiter = QueueServerTerminationWaiterImpl(
        logger: .noOp,
        pollInterval: 0.1,
        queueServerTerminationPolicy: AutomaticTerminationPolicy.stayAlive
    )
    
    let waiterQueue = DispatchQueue(label: "waiter queue")
    let impactQueue = DispatchQueue(label: "impact queue")

    func test___queue_server_waiter_should_wait___until_first_worker_registers() throws {
        queueServer.hasAnyAliveWorker = false

        impactQueue.async { [weak self] in
            self?.queueServer.hasAnyAliveWorker = true
        }

        try waiter.waitForWorkerToAppear(queueServer: queueServer, timeout: 60.0)
    }
    
    func test___queue_server_waiter_should_wait___while_automatic_termination_is_not_allowed() throws {
        let expectation = self.expectation(description: "waiter should wait while automatic termination is not allowed and it has alive workers")
        expectation.isInverted = true
        
        queueServer.isDepleted = true
        
        waiterQueue.async { [weak self] in
            self?.wait()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test___queue_server_waiter_should_wait___while_queue_is_not_depleted() throws {
        let expectation = self.expectation(description: "waiter should wait while it has alive workers and queue is not depleted")
        expectation.isInverted = true
        
        automaticTerminationController.isTerminationAllowed = true
        queueServer.isDepleted = false
        
        waiterQueue.async { [weak self] in
            self?.wait()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test___queue_server_waiter_stops___after_all_workers_have_died() throws {
        let expectation = self.expectation(description: "waiter should stop waiting when queue has no alive workers")
        
        waiterQueue.async { [weak self] in
            self?.wait()
            expectation.fulfill()
        }
        
        impactQueue.asyncAfter(deadline: .now() + 0.1) {
            self.queueServer.hasAnyAliveWorker = false
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    func test___queue_server_waiter_stops___after_automatic_termination() throws {
        let expectation = self.expectation(description: "waiter should stop when automatic termination controller allows")
        queueServer.isDepleted = true
        
        waiterQueue.async { [weak self] in
            self?.wait()
            expectation.fulfill()
        }
        
        impactQueue.asyncAfter(deadline: .now() + 0.1) {
            self.automaticTerminationController.isTerminationAllowed = true
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    func test___queue_server_waiter_stops___after_automatic_termination_is_allowed_and_queue_depletes() throws {
        automaticTerminationController.isTerminationAllowed = true
        
        let expectation = self.expectation(description: "waiter should stop when automatic termination controller allows and after queue has been depleted")
        
        waiterQueue.async { [weak self] in
            self?.wait()
            expectation.fulfill()
        }
        
        impactQueue.asyncAfter(deadline: .now() + 0.1) {
            self.queueServer.isDepleted = true
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    private func wait() {
        do {
            try waiter.waitForAllJobsToFinish(
                queueServer: queueServer,
                automaticTerminationController: automaticTerminationController
            )
        } catch {
            XCTFail("Unexpectidly caught \(error)")
        }
    }
}
