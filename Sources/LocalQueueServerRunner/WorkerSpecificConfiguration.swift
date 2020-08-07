import Foundation
import QueueModels

public struct WorkerSpecificConfiguration: Decodable {
    public let numberOfSimulators: UInt

    public init(
        numberOfSimulators: UInt
    ) {
        self.numberOfSimulators = numberOfSimulators
    }
}
