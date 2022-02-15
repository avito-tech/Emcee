import Foundation
import EmceeLogging
import EmceeLoggingModels
import ProcessController

public class ProcessControllerWrappingTestRunnerInvocation: TestRunnerInvocation, TestRunnerRunningInvocation {
    
    private let processController: ProcessController
    private let logger: ContextualLogger
    
    public init(
        processController: ProcessController,
        logger: ContextualLogger
    ) {
        self.processController = processController
        self.logger = logger
    }
    
    public func startExecutingTests() throws -> TestRunnerRunningInvocation {
        try processController.start()
        return self
    }
    
    public func cancel() {
        processController.signalAndForceKillIfNeeded(
            terminationSignal: SIGINT,
            terminationSignalTimeout: 150,
            onKill: { [logger, pidInfo = processController.subprocessInfo.pidInfo] in
                logger.error(
                    "Killing test runner process",
                    subprocessPidInfo: pidInfo
                )
            }
        )
    }
    
    public var pidInfo: PidInfo {
        PidInfo(pid: processController.processId, name: processController.processName)
    }
    
    public func wait() {
        processController.waitForProcessToDie()
    }
}
