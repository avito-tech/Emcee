import Foundation
import Models

public final class SchedulerBucket: CustomStringConvertible, Equatable {
    public let bucketId: BucketId
    public let testEntries: [TestEntry]
    public let buildArtifacts: BuildArtifacts
    public let pluginLocations: Set<PluginLocation>
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testType: TestType
    public let toolResources: ToolResources
    public let toolchainConfiguration: ToolchainConfiguration
    
    public var description: String {
        var result = [String]()
        
        result.append("\(bucketId)")
        result.append("testEntries: " + testEntries.map { $0.testName.stringValue }.joined(separator: ","))
        result.append("buildArtifacts: \(buildArtifacts)")
        result.append("pluginLocations: \(pluginLocations)")
        result.append("testDestination: \(testDestination)")
        result.append("testExecutionBehavior: \(testExecutionBehavior)")
        result.append("testTimeoutConfiguration: \(testTimeoutConfiguration)")
        result.append("testType: \(testType)")
        result.append("toolResources: \(toolResources)")
        result.append("simulatorSettings: \(simulatorSettings)")
        result.append("toolchainConfiguration: \(toolchainConfiguration)")
        
        return "<\((type(of: self))) " + result.joined(separator: " ") + ">"
    }

    public init(
        bucketId: BucketId,
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        pluginLocations: Set<PluginLocation>,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType,
        toolResources: ToolResources,
        toolchainConfiguration: ToolchainConfiguration
    ) {
        self.bucketId = bucketId
        self.testEntries = testEntries
        self.buildArtifacts = buildArtifacts
        self.pluginLocations = pluginLocations
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testType = testType
        self.toolResources = toolResources
        self.toolchainConfiguration = toolchainConfiguration
    }
    
    public static func from(bucket: Bucket, testExecutionBehavior: TestExecutionBehavior) -> SchedulerBucket {
        return SchedulerBucket(
            bucketId: bucket.bucketId,
            testEntries: bucket.testEntries,
            buildArtifacts: bucket.buildArtifacts,
            pluginLocations: bucket.pluginLocations,
            simulatorSettings: bucket.simulatorSettings,
            testDestination: bucket.testDestination,
            testExecutionBehavior: testExecutionBehavior,
            testTimeoutConfiguration: bucket.testTimeoutConfiguration,
            testType: bucket.testType,
            toolResources: bucket.toolResources,
            toolchainConfiguration: bucket.toolchainConfiguration
        )
    }
    
    public static func == (left: SchedulerBucket, right: SchedulerBucket) -> Bool {
        return left.bucketId == right.bucketId
            && left.testEntries == right.testEntries
            && left.buildArtifacts == right.buildArtifacts
            && left.pluginLocations == right.pluginLocations
            && left.simulatorSettings == right.simulatorSettings
            && left.testDestination == right.testDestination
            && left.testExecutionBehavior == right.testExecutionBehavior
            && left.testTimeoutConfiguration == right.testTimeoutConfiguration
            && left.testType == right.testType
            && left.toolResources == right.toolResources
            && left.toolchainConfiguration == right.toolchainConfiguration
    }
}
