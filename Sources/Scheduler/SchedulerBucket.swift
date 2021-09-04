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
    public let pluginLocations: Set<PluginLocation>
    public let runTestsBucketPayload: RunTestsBucketPayload
    
    public var description: String {
        var result = [String]()
        
        result.append("\(bucketId)")
        result.append("buildArtifacts: \(runTestsBucketPayload.buildArtifacts)")
        result.append("developerDir: \(runTestsBucketPayload.developerDir)")
        result.append("pluginLocations: \(pluginLocations)")
        result.append("simulatorControlTool: \(runTestsBucketPayload.simulatorControlTool)")
        result.append("simulatorOperationTimeouts: \(runTestsBucketPayload.simulatorOperationTimeouts)")
        result.append("simulatorSettings: \(runTestsBucketPayload.simulatorSettings)")
        result.append("testDestination: \(runTestsBucketPayload.testDestination)")
        result.append("testEntries: " + runTestsBucketPayload.testEntries.map { $0.testName.stringValue }.joined(separator: ","))
        result.append("testExecutionBehavior: \(runTestsBucketPayload.testExecutionBehavior)")
        result.append("testRunnerTool: \(runTestsBucketPayload.testRunnerTool)")
        result.append("testTimeoutConfiguration: \(runTestsBucketPayload.testTimeoutConfiguration)")
        result.append("testType: \(runTestsBucketPayload.testType)")
        
        return "<\((type(of: self))) " + result.joined(separator: " ") + ">"
    }

    public init(
        bucketId: BucketId,
        analyticsConfiguration: AnalyticsConfiguration,
        pluginLocations: Set<PluginLocation>,
        runTestsBucketPayload: RunTestsBucketPayload
    ) {
        self.bucketId = bucketId
        self.analyticsConfiguration = analyticsConfiguration
        self.pluginLocations = pluginLocations
        self.runTestsBucketPayload = runTestsBucketPayload
    }
    
    public static func from(bucket: Bucket, testExecutionBehavior: TestExecutionBehavior) -> SchedulerBucket {
        return SchedulerBucket(
            bucketId: bucket.bucketId,
            analyticsConfiguration: bucket.analyticsConfiguration,
            pluginLocations: bucket.pluginLocations,
            runTestsBucketPayload: RunTestsBucketPayload(
                buildArtifacts: bucket.runTestsBucketPayload.buildArtifacts,
                developerDir: bucket.runTestsBucketPayload.developerDir,
                simulatorControlTool: bucket.runTestsBucketPayload.simulatorControlTool,
                simulatorOperationTimeouts: bucket.runTestsBucketPayload.simulatorOperationTimeouts,
                simulatorSettings: bucket.runTestsBucketPayload.simulatorSettings,
                testDestination: bucket.runTestsBucketPayload.testDestination,
                testEntries: bucket.runTestsBucketPayload.testEntries,
                testExecutionBehavior: testExecutionBehavior,
                testRunnerTool: bucket.runTestsBucketPayload.testRunnerTool,
                testTimeoutConfiguration: bucket.runTestsBucketPayload.testTimeoutConfiguration,
                testType: bucket.runTestsBucketPayload.testType
            )
        )
    }
}
