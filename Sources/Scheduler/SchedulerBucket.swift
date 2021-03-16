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
    public let buildArtifacts: BuildArtifacts
    public let developerDir: DeveloperDir
    public let pluginLocations: Set<PluginLocation>
    public let simulatorControlTool: SimulatorControlTool
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testEntries: [TestEntry]
    public let testExecutionBehavior: TestExecutionBehavior
    public let testRunnerTool: TestRunnerTool
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testType: TestType
    
    public var description: String {
        var result = [String]()
        
        result.append("\(bucketId)")
        result.append("buildArtifacts: \(buildArtifacts)")
        result.append("developerDir: \(developerDir)")
        result.append("pluginLocations: \(pluginLocations)")
        result.append("simulatorControlTool: \(simulatorControlTool)")
        result.append("simulatorOperationTimeouts: \(simulatorOperationTimeouts)")
        result.append("simulatorSettings: \(simulatorSettings)")
        result.append("testDestination: \(testDestination)")
        result.append("testEntries: " + testEntries.map { $0.testName.stringValue }.joined(separator: ","))
        result.append("testExecutionBehavior: \(testExecutionBehavior)")
        result.append("testRunnerTool: \(testRunnerTool)")
        result.append("testTimeoutConfiguration: \(testTimeoutConfiguration)")
        result.append("testType: \(testType)")
        
        return "<\((type(of: self))) " + result.joined(separator: " ") + ">"
    }

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        bucketId: BucketId,
        buildArtifacts: BuildArtifacts,
        developerDir: DeveloperDir,
        pluginLocations: Set<PluginLocation>,
        simulatorControlTool: SimulatorControlTool,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testEntries: [TestEntry],
        testExecutionBehavior: TestExecutionBehavior,
        testRunnerTool: TestRunnerTool,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.bucketId = bucketId
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.pluginLocations = pluginLocations
        self.simulatorControlTool = simulatorControlTool
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testEntries = testEntries
        self.testExecutionBehavior = testExecutionBehavior
        self.testRunnerTool = testRunnerTool
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testType = testType
    }
    
    public static func from(bucket: Bucket, testExecutionBehavior: TestExecutionBehavior) -> SchedulerBucket {
        return SchedulerBucket(
            analyticsConfiguration: bucket.analyticsConfiguration,
            bucketId: bucket.bucketId,
            buildArtifacts: bucket.buildArtifacts,
            developerDir: bucket.developerDir,
            pluginLocations: bucket.pluginLocations,
            simulatorControlTool: bucket.simulatorControlTool,
            simulatorOperationTimeouts: bucket.simulatorOperationTimeouts,
            simulatorSettings: bucket.simulatorSettings,
            testDestination: bucket.testDestination,
            testEntries: bucket.testEntries,
            testExecutionBehavior: testExecutionBehavior,
            testRunnerTool: bucket.testRunnerTool,
            testTimeoutConfiguration: bucket.testTimeoutConfiguration,
            testType: bucket.testType
        )
    }
}
