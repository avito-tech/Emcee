import BuildArtifacts
import DeveloperDirModels
import Foundation
import MetricsExtensions
import PluginSupport
import QueueModels
import SimulatorPoolModels

public struct SchedulerBucket: CustomStringConvertible, Equatable {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let bucketId: BucketId
    public let bucketPayloadContainer: BucketPayloadContainer
    
    public var description: String {
        return "<\((type(of: self))) \(bucketId) \(bucketPayloadContainer)>"
    }

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        bucketId: BucketId,
        bucketPayloadContainer: BucketPayloadContainer
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.bucketId = bucketId
        self.bucketPayloadContainer = bucketPayloadContainer
    }
}
