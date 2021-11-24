import Foundation
import QueueModels

public struct WorkerSpecificConfiguration: Codable, Hashable {
    public let numberOfSimulators: UInt

    public init(
        numberOfSimulators: UInt
    ) {
        self.numberOfSimulators = numberOfSimulators
    }
}
