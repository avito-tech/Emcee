import Foundation
import QueueModels

public struct WorkerIdsResponse: Codable, Equatable {
    public let workerIds: Set<WorkerId>
    
    public init(workerIds: Set<WorkerId>) {
        self.workerIds = workerIds
    }
}
