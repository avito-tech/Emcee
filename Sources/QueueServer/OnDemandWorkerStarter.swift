import Foundation
import QueueModels

public protocol OnDemandWorkerStarter {
    func start(workerId: WorkerId) throws
}
