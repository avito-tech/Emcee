import Foundation
import ProcessController
import SynchronousWaiter

public final class FakeProcessController: ProcessController {
    public var subprocess: Subprocess

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
    
    public func waitForProcessToDie() {
        try? SynchronousWaiter().waitWhile { isProcessRunning }
    }
    
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
    
    // Stdout
    
    public var stdoutListeners = [StdoutListener]()
    
    public func onStdout(listener: @escaping StdoutListener) {
        stdoutListeners.append(listener)
    }
    
    public func broadcastStdout(data: Data) {
        stdoutListeners.forEach { $0(self, data, { }) }
    }
    
    // Stderr
    
    public var stderrListeners = [StdoutListener]()
    
    public func onStderr(listener: @escaping StderrListener) {
        stderrListeners.append(listener)
    }
    
    public func broadcastStderr(data: Data) {
        stderrListeners.forEach { $0(self, data, { }) }
    }
    
    // Silence
    
    public var silenceListeners = [SilenceListener]()
    
    public func onSilence(listener: @escaping SilenceListener) {
        silenceListeners.append(listener)
    }
    
    public func broadcastSilence() {
        silenceListeners.forEach { $0(self, { }) }
    }
}
