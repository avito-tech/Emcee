import Foundation
import QueueModels

public struct WorkerSpecificConfiguration: Decodable, Equatable {
    public let numberOfSimulators: UInt

    public init(
        numberOfSimulators: UInt
    ) {
        self.numberOfSimulators = numberOfSimulators
    }
}
