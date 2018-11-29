import Foundation
import WorkerAlivenessTracker

public final class MutableWorkerAlivenessProvider: WorkerAlivenessProvider {
    public var workerAliveness = [String: WorkerAliveness]()
    
    public init() {}
}
