import Foundation
import MetricsExtensions
import LoggingSetup
import QueueModels

public struct WorkerConfiguration: Codable, Equatable {
    public let globalAnalyticsConfiguration: AnalyticsConfiguration?
    public let numberOfSimulators: UInt
    public let payloadSignature: PayloadSignature

    public init(
        globalAnalyticsConfiguration: AnalyticsConfiguration?,
        numberOfSimulators: UInt,
        payloadSignature: PayloadSignature
    ) {
        self.globalAnalyticsConfiguration = globalAnalyticsConfiguration
        self.numberOfSimulators = numberOfSimulators
        self.payloadSignature = payloadSignature
    }
}
