import DistWorkerModels
import Foundation
import QueueModels

public struct WorkerDisabledResponse: Codable, Equatable {
    public let workerId: WorkerId
    
    public init(workerId: WorkerId) {
        self.workerId = workerId
    }
}
