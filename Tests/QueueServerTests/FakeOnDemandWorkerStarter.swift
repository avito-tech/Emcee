import Foundation
import QueueModels
import QueueServer

public final class FakeOnDemandWorkerStarter: OnDemandWorkerStarter {
    public init() {}
    
    public var startedWorkerId: WorkerId?
    
    public func start(workerId: WorkerId) throws {
        startedWorkerId = workerId
    }
}
