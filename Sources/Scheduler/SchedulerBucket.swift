import BuildArtifacts
import DeveloperDirModels
import Foundation
import MetricsExtensions
import PluginSupport
import QueueModels
import SimulatorPoolModels
import RunnerModels

public struct SchedulerBucket: CustomStringConvertible, Equatable {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let bucketId: BucketId
    public let bucketPayload: BucketPayload
    
    public var description: String {
        return "<\((type(of: self))) \(bucketId) \(bucketPayload)>"
    }

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        bucketId: BucketId,
        bucketPayload: BucketPayload
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.bucketId = bucketId
        self.bucketPayload = bucketPayload
    }
}
