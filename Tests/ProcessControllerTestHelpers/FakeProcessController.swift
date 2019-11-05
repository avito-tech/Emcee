import Foundation
import ProcessController

public final class FakeProcessController: ProcessController {
    public let subprocess: Subprocess

    public init(subprocess: Subprocess) {
        self.subprocess = subprocess
    }
    
    public var processName: String {
        return try! subprocess.arguments[0].stringValue().lastPathComponent
    }
    
    public var processId: Int32 {
        return 0
    }
    
    public func start() {}
    public func startAndListenUntilProcessDies() {}
    public func waitForProcessToDie() {}
    
    public var overridedProcessStatus: ProcessStatus = .notStarted
    
    public func processStatus() -> ProcessStatus {
        return overridedProcessStatus
    }
    
    public func writeToStdIn(data: Data) throws {}    
    
    public func terminateAndForceKillIfNeeded() {
        overridedProcessStatus = .terminated(exitCode: SIGTERM)
    }
    
    public func interruptAndForceKillIfNeeded() {
        overridedProcessStatus = .terminated(exitCode: SIGINT)
    }
    
    public weak var delegate: ProcessControllerDelegate?
    
    public func onStdout(listener: @escaping StdoutListener) {}
    public func onStderr(listener: @escaping StderrListener) {}
    public func onSilence(listener: @escaping SilenceListener) {}
}
