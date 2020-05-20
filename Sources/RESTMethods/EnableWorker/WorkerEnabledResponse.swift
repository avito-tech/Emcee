import DistWorkerModels
import Foundation
import Models

public struct WorkerEnabledResponse: Codable, Equatable {
    public let workerId: WorkerId
    
    public init(workerId: WorkerId) {
        self.workerId = workerId
    }
}
