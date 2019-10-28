import Foundation
import Logging

public protocol ProcessController: class {
    var subprocess: Subprocess { get }
    var processName: String { get }
    var processId: Int32 { get }
    
    func start()
    func startAndListenUntilProcessDies()
    func waitForProcessToDie()
    func processStatus() -> ProcessStatus
    
    func writeToStdIn(data: Data) throws
    func terminateAndForceKillIfNeeded()
    func interruptAndForceKillIfNeeded()
    
    var delegate: ProcessControllerDelegate? { get set }
}

public extension ProcessController {
    var isProcessRunning: Bool {
        return processStatus() == .stillRunning
    }
    
    var subprocessInfo: SubprocessInfo {
        return SubprocessInfo(subprocessId: processId, subprocessName: processName)
    }
}
