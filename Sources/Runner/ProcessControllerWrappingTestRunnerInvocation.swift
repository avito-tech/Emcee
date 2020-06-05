import Foundation
import Logging
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
    
    public var subprocessInfo: SubprocessInfo {
        SubprocessInfo(subprocessId: processController.processId, subprocessName: processController.processName)
    }
    
    public var output: StandardStreamsCaptureConfig {
        processController.subprocess.standardStreamsCaptureConfig
    }
    
    public func wait() {
        processController.waitForProcessToDie()
    }
}
