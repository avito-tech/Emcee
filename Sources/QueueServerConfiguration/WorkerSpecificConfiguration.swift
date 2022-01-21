import Foundation
import LogStreamingModels
import QueueModels

public struct WorkerSpecificConfiguration: Codable, Hashable {
    public let numberOfSimulators: UInt
    public let maximumCacheSize: Int
    public let maximumCacheTTL: TimeInterval
    public let logStreamingMode: WorkerLogStreamingMode

    public init(
        numberOfSimulators: UInt,
        maximumCacheSize: Int,
        maximumCacheTTL: TimeInterval,
        logStreamingMode: WorkerLogStreamingMode
    ) {
        self.numberOfSimulators = numberOfSimulators
        self.maximumCacheSize = maximumCacheSize
        self.maximumCacheTTL = maximumCacheTTL
        self.logStreamingMode = logStreamingMode
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        numberOfSimulators = try container.decode(UInt.self, forKey: .numberOfSimulators)
        maximumCacheSize = try container.decodeIfPresent(Int.self, forKey: .maximumCacheSize) ??
            QueueServerConfigurationDefaultValues.defaultWorkerConfiguration.maximumCacheSize
        maximumCacheTTL = try container.decodeIfPresent(TimeInterval.self, forKey: .maximumCacheTTL) ??
            QueueServerConfigurationDefaultValues.defaultWorkerConfiguration.maximumCacheTTL
        logStreamingMode = try container.decodeIfPresent(WorkerLogStreamingMode.self, forKey: .logStreamingMode) ??
            QueueServerConfigurationDefaultValues.defaultWorkerConfiguration.logStreamingMode
    }
}
