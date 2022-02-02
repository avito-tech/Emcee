import Foundation
import EmceeLogging
import EmceeLoggingModels
import ProcessController

public class ProcessControllerWrappingTestRunnerInvocation: TestRunnerInvocation, TestRunnerRunningInvocation {
    
    private let processController: ProcessController
    
    public init(processController: ProcessController) {
        self.processController = processController
    }
    
    public func startExecutingTests() throws -> TestRunnerRunningInvocation {
        try processController.start()
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
