import Foundation
import WorkerAlivenessTracker

public final class MutableWorkerAlivenessProvider: WorkerAlivenessProvider {
    public func markWorkerAsAlive(workerId: String) {
        
    }
    
    public func set(bucketIdsBeingProcessed: Set<String>, workerId: String) {
        
    }
    
    public func didDequeueBucket(bucketId: String, workerId: String) {
        
    }
    
    public var workerAliveness = [String: WorkerAliveness]()
    
    public init() {}
}
