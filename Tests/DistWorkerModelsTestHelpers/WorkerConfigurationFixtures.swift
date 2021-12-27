import DistWorkerModels
import Foundation
import MetricsExtensions
import LoggingSetup
import QueueModels

public final class WorkerConfigurationFixtures {
    public static let workerConfiguration = WorkerConfiguration(
        globalAnalyticsConfiguration: AnalyticsConfiguration(),
        numberOfSimulators: 2,
        payloadSignature: PayloadSignature(value: "payloadSignature"),
        maximumCacheSize: 10*1024,
        maximumCacheTTL: 3600
    )
}
