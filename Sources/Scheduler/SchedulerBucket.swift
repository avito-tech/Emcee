import Foundation
import Models

public struct SchedulerBucket: CustomStringConvertible, Equatable {
    public let bucketId: BucketId
    public let developerDir: DeveloperDir
    public let testEntries: [TestEntry]
    public let buildArtifacts: BuildArtifacts
    public let pluginLocations: Set<PluginLocation>
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testType: TestType
    public let toolResources: ToolResources
    
    public var description: String {
        var result = [String]()
        
        result.append("\(bucketId)")
        result.append("testEntries: " + testEntries.map { $0.testName.stringValue }.joined(separator: ","))
        result.append("buildArtifacts: \(buildArtifacts)")
        result.append("developerDir: \(developerDir)")
        result.append("pluginLocations: \(pluginLocations)")
        result.append("testDestination: \(testDestination)")
        result.append("testExecutionBehavior: \(testExecutionBehavior)")
        result.append("testTimeoutConfiguration: \(testTimeoutConfiguration)")
        result.append("testType: \(testType)")
        result.append("toolResources: \(toolResources)")
        result.append("simulatorSettings: \(simulatorSettings)")
        
        return "<\((type(of: self))) " + result.joined(separator: " ") + ">"
    }

    public init(
        bucketId: BucketId,
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        developerDir: DeveloperDir,
        pluginLocations: Set<PluginLocation>,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType,
        toolResources: ToolResources
    ) {
        self.bucketId = bucketId
        self.testEntries = testEntries
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.pluginLocations = pluginLocations
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testType = testType
        self.toolResources = toolResources
    }
    
    public static func from(bucket: Bucket, testExecutionBehavior: TestExecutionBehavior) -> SchedulerBucket {
        return SchedulerBucket(
            bucketId: bucket.bucketId,
            testEntries: bucket.testEntries,
            buildArtifacts: bucket.buildArtifacts,
            developerDir: bucket.developerDir,
            pluginLocations: bucket.pluginLocations,
            simulatorSettings: bucket.simulatorSettings,
            testDestination: bucket.testDestination,
            testExecutionBehavior: testExecutionBehavior,
            testTimeoutConfiguration: bucket.testTimeoutConfiguration,
            testType: bucket.testType,
            toolResources: bucket.toolResources
        )
    }
}
