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
    public let testType: TestType

    public init(
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        toolResources: ToolResources,
        testType: TestType
        )
    {
        self.testEntries = testEntries
        self.buildArtifacts = buildArtifacts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.toolResources = toolResources
        self.testType = testType
        self.bucketId = Bucket.generateBucketId(
            testEntries: testEntries,
            buildArtifacts: buildArtifacts,
            simulatorSettings: simulatorSettings,
            testDestination: testDestination,
            testExecutionBehavior: testExecutionBehavior,
            toolResources: toolResources,
            testType: testType
        )
    }
    
    private static func generateBucketId(
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        toolResources: ToolResources,
        testType: TestType
        ) -> String
    {
        let buildArtifactsId = (buildArtifacts.appBundle?.description ?? "null") + (buildArtifacts.runner?.description ?? "null") + buildArtifacts.xcTestBundle.description
            + buildArtifacts.additionalApplicationBundles.map { $0.description }.sorted().joined()
        
        let tests: String = testEntries.map { $0.testName }.sorted().joined()
            + testDestination.destinationString
            + buildArtifactsId
            + testExecutionBehavior.environment.map { "\($0)=\($1)" }.sorted().joined() + "\(testExecutionBehavior.numberOfRetries)"
            + toolResources.fbsimctl.description + toolResources.fbxctest.description
            + simulatorSettings.description
            + testType.rawValue
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
        return "<\((type(of: self))) \(bucketId.debugDescription) \(testType) \(testDestination), \(toolResources), \(buildArtifacts), \(testEntries.debugDescription)>"
    }
    
    public var hashValue: Int {
        return bucketId.hashValue
    }
    
    public static func == (left: Bucket, right: Bucket) -> Bool {
        return left.bucketId == right.bucketId
    }
}
