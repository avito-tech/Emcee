import Foundation

public protocol WorkerAlivenessProvider: class {
    var workerAliveness: [String: WorkerAliveness] { get }
}

public extension WorkerAlivenessProvider {
    var hasAnyAliveWorker: Bool {
        return workerAliveness.contains { _, value in
            value == .alive
        }
    }
    
    func alivenessForWorker(workerId: String) -> WorkerAliveness {
        return workerAliveness[workerId] ?? .notRegistered
    }
}
