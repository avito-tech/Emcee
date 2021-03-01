import Foundation
import EmceeLogging
import ProcessController

public class ProcessControllerWrappingTestRunnerInvocation: TestRunnerInvocation, TestRunnerRunningInvocation {
    
    private let processController: ProcessController
    
    public init(processController: ProcessController) {
        self.processController = processController
    }
    
    public func startExecutingTests() -> TestRunnerRunningInvocation {
        processController.start()
        return self
    }
    
    public func cancel() {
        processController.terminateAndForceKillIfNeeded()
    }
    
    public var pidInfo: PidInfo {
        PidInfo(pid: processController.processId, name: processController.processName)
    }
    
    public func wait() {
        processController.waitForProcessToDie()
    }
}
