import Foundation
import LoggingSetup
import Models

public struct WorkerConfiguration: Codable, Equatable {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let numberOfSimulators: UInt
    public let payloadSignature: PayloadSignature
    public let reportAliveInterval: TimeInterval

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        numberOfSimulators: UInt,
        payloadSignature: PayloadSignature,
        reportAliveInterval: TimeInterval
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.numberOfSimulators = numberOfSimulators
        self.payloadSignature = payloadSignature
        self.reportAliveInterval = reportAliveInterval
    }
}
