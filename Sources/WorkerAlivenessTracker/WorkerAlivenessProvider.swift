import Foundation

public protocol WorkerAlivenessProvider: class {
    func alivenessForWorker(workerId: String) -> WorkerAliveness
    var hasAnyAliveWorker: Bool { get }
}
