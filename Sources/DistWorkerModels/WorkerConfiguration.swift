import Foundation
import LoggingSetup
import QueueModels

public struct WorkerConfiguration: Codable, Equatable {
    public let numberOfSimulators: UInt
    public let payloadSignature: PayloadSignature

    public init(
        numberOfSimulators: UInt,
        payloadSignature: PayloadSignature
    ) {
        self.numberOfSimulators = numberOfSimulators
        self.payloadSignature = payloadSignature
    }
}
