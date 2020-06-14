import DistWorkerModels
import Foundation
import Models
import WorkerAlivenessModels

public struct WorkerStatusResponse: Codable, Equatable {
    public let workerAliveness: [WorkerId: WorkerAliveness]

    public init(workerAliveness: [WorkerId: WorkerAliveness]) {
        self.workerAliveness = workerAliveness
    }
}
