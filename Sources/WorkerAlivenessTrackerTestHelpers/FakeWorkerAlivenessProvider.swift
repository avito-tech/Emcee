import Foundation
import WorkerAlivenessTracker

public final class MutableWorkerAlivenessProvider: WorkerAlivenessProvider {
    
    public init() {}
    
    public var aliveness = [String: WorkerAliveness]()
    
    public func alivenessForWorker(workerId: String) -> WorkerAliveness {
        return aliveness[workerId] ?? .notRegistered
    }
    
    public var hasAnyAliveWorker: Bool {
        return !aliveness.isEmpty
    }
}
