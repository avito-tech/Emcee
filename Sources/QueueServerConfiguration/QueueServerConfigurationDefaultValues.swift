import AutomaticTermination
import Foundation
import MetricsExtensions
import QueueModels

public enum QueueServerConfigurationDefaultValues {
    public static let globalAnalyticsConfiguration: AnalyticsConfiguration = AnalyticsConfiguration()
    public static let checkAgainTimeInterval: TimeInterval = 30
    public static let queueServerTerminationPolicy: AutomaticTerminationPolicy = .stayAlive
    public static let defaultWorkerConfiguration: WorkerSpecificConfiguration = WorkerSpecificConfiguration(
        numberOfSimulators: 3,
        maximumCacheSize: 10 * 1024 * 1024 * 1024,
        maximumCacheTTL: 3600
    )
    public static let workerStartMode: WorkerStartMode = .queueStartsItsWorkersOverSshAndLaunchd
    public static let useOnlyIPv4: Bool = true
}
