import Foundation
import ProcessController
import ProcessControllerTestHelpers
import Runner
import XCTest

final class ProcessControllerWrappingTestRunnerInvocationTests: XCTestCase {
    lazy var processController = FakeProcessController(
        subprocess: Subprocess(arguments: [])
    )
    lazy var testRunnerInvocation = ProcessControllerWrappingTestRunnerInvocation(
        processController: processController
    )
    
    func test___starting_test_invocation___executes_process() {
        processController.onStart { [weak self] _, _ in
            self?.processController.overridedProcessStatus = .stillRunning
        }
        _ = testRunnerInvocation.startExecutingTests()
        XCTAssertTrue(processController.isProcessRunning)
    }
    
    func test___cancelling_test_execution___terminates_process() {
        testRunnerInvocation.startExecutingTests().cancel()
        XCTAssertFalse(processController.isProcessRunning)
        XCTAssertEqual(processController.signalsSent, [SIGTERM])
    }
    
    func test___waiting_for_test_execution_to_complete___waits_for_process_to_terminate() {
        let expectation = XCTestExpectation(description: "waited for process to terminate")
        
        let impactQueue = DispatchQueue(label: "impactQueue")
        impactQueue.asyncAfter(deadline: .now() + .seconds(1)) {
            self.processController.overridedProcessStatus = .terminated(exitCode: 0)
            expectation.fulfill()
        }
        testRunnerInvocation.startExecutingTests().wait()
        
        wait(for: [expectation], timeout: 5)
    }
}
