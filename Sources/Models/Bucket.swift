import Extensions
import Foundation

public final class Bucket: Codable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let bucketId: String
    public let testEntries: [TestEntry]
    public let buildArtifacts: BuildArtifacts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior
    public let toolResources: ToolResources

    public init(
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        toolResources: ToolResources
        )
    {
        self.testEntries = testEntries
        self.buildArtifacts = buildArtifacts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.toolResources = toolResources
        self.bucketId = Bucket.generateBucketId(
            testEntries: testEntries,
            buildArtifacts: buildArtifacts,
            simulatorSettings: simulatorSettings,
            testDestination: testDestination,
            testExecutionBehavior: testExecutionBehavior,
            toolResources: toolResources
        )
    }
    
    private static func generateBucketId(
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        toolResources: ToolResources
        ) -> String
    {
        
        let tests: String = testEntries.map { $0.testName }.sorted().joined()
            + testDestination.destinationString
            + buildArtifacts.appBundle.description + buildArtifacts.runner.description + buildArtifacts.xcTestBundle.description
            + buildArtifacts.additionalApplicationBundles.map { $0.description }.sorted().joined()
            + testExecutionBehavior.environment.map { "\($0)=\($1)" }.sorted().joined() + "\(testExecutionBehavior.numberOfRetries)"
            + toolResources.fbsimctl.description + toolResources.fbxctest.description
            + simulatorSettings.description
        do {
            return try tests.avito_sha256Hash(encoding: .utf8)
        } catch {
            preconditionFailure("Unable to generate bucket id as SHA256 from the following string: '\(tests)'")
        }
    }
    
    public var description: String {
        return "<\((type(of: self))) \(bucketId), \(testEntries.count) tests>"
    }
    
    public var debugDescription: String {
        return "<\((type(of: self))) \(bucketId.debugDescription) \(testDestination), \(toolResources), \(buildArtifacts), \(testEntries.debugDescription)>"
    }
    
    public var hashValue: Int {
        return bucketId.hashValue
    }
    
    public static func == (left: Bucket, right: Bucket) -> Bool {
        return left.bucketId == right.bucketId
    }
}
