import Foundation

public enum WorkerSpecificConfigurationDefaultValues {
    public static let defaultWorkerConfiguration: WorkerSpecificConfiguration = WorkerSpecificConfiguration(
        numberOfSimulators: 3,
        maximumCacheSize: 10 * 1024 * 1024 * 1024,
        maximumCacheTTL: 3600
    )
}
