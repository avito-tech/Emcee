import DistWorkerModels
import EmceeExtensions
import Foundation
import MetricsExtensions
import QueueModels

public final class WorkerConfigurationFixtures {
    public static let workerConfiguration = WorkerConfiguration(
        globalAnalyticsConfiguration: AnalyticsConfiguration(),
        numberOfSimulators: 2,
        payloadSignature: PayloadSignature(value: "payloadSignature"),
        maximumCacheSize: 10*1024,
        maximumCacheTTL: 3600,
        portRange: PortRange(from: 41000, rangeLength: 10)
    )
}
