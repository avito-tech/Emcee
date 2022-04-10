import EmceeExtensions
import Foundation
import MetricsExtensions
import QueueModels

public struct WorkerConfiguration: Codable, Equatable {
    public let globalAnalyticsConfiguration: AnalyticsConfiguration
    public let numberOfSimulators: UInt
    public let payloadSignature: PayloadSignature
    public let maximumCacheSize: Int
    public let maximumCacheTTL: TimeInterval
    public let portRange: PortRange

    public init(
        globalAnalyticsConfiguration: AnalyticsConfiguration,
        numberOfSimulators: UInt,
        payloadSignature: PayloadSignature,
        maximumCacheSize: Int,
        maximumCacheTTL: TimeInterval,
        portRange: PortRange
    ) {
        self.globalAnalyticsConfiguration = globalAnalyticsConfiguration
        self.numberOfSimulators = numberOfSimulators
        self.payloadSignature = payloadSignature
        self.maximumCacheSize = maximumCacheSize
        self.maximumCacheTTL = maximumCacheTTL
        self.portRange = portRange
    }
    
    public var description: String {
        "<\(type(of: self)): globalAnalyticsConfiguration=\(globalAnalyticsConfiguration), numberOfSimulators=\(numberOfSimulators), portRange=\(portRange)>"
    }
}
