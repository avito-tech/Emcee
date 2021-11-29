import BuildArtifacts
import DeveloperDirModels
import Foundation
import MetricsExtensions
import PluginSupport
import QueueModels
import SimulatorPoolModels
import RunnerModels

public struct SchedulerBucket: CustomStringConvertible, Equatable {
    public let bucketId: BucketId
    public let analyticsConfiguration: AnalyticsConfiguration
    public let payload: Payload
    
    public var description: String {
        var result = [String]()
        
        result.append("\(bucketId)")
        result.append("buildArtifacts: \(payload.buildArtifacts)")
        result.append("developerDir: \(payload.developerDir)")
        result.append("pluginLocations: \(payload.pluginLocations)")
        result.append("simulatorOperationTimeouts: \(payload.simulatorOperationTimeouts)")
        result.append("simulatorSettings: \(payload.simulatorSettings)")
        result.append("testDestination: \(payload.testDestination)")
        result.append("testEntries: " + payload.testEntries.map { $0.testName.stringValue }.joined(separator: ","))
        result.append("testExecutionBehavior: \(payload.testExecutionBehavior)")
        result.append("testTimeoutConfiguration: \(payload.testTimeoutConfiguration)")
        
        return "<\((type(of: self))) " + result.joined(separator: " ") + ">"
    }

    public init(
        bucketId: BucketId,
        analyticsConfiguration: AnalyticsConfiguration,
        payload: Payload
    ) {
        self.bucketId = bucketId
        self.analyticsConfiguration = analyticsConfiguration
        self.payload = payload
    }
    
    public static func from(bucket: Bucket, testExecutionBehavior: TestExecutionBehavior) -> SchedulerBucket {
        return SchedulerBucket(
            bucketId: bucket.bucketId,
            analyticsConfiguration: bucket.analyticsConfiguration,
            payload: Payload(
                buildArtifacts: bucket.payload.buildArtifacts,
                developerDir: bucket.payload.developerDir,
                pluginLocations: bucket.payload.pluginLocations,
                simulatorOperationTimeouts: bucket.payload.simulatorOperationTimeouts,
                simulatorSettings: bucket.payload.simulatorSettings,
                testDestination: bucket.payload.testDestination,
                testEntries: bucket.payload.testEntries,
                testExecutionBehavior: testExecutionBehavior,
                testTimeoutConfiguration: bucket.payload.testTimeoutConfiguration
            )
        )
    }
}
