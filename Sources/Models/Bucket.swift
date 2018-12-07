import Extensions
import Foundation

public final class Bucket: Codable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let bucketId: String
    public let testEntries: [TestEntry]
    public let buildArtifacts: BuildArtifacts
    public let environment: [String: String]
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let toolResources: ToolResources

    public init(
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        environment: [String: String],
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        toolResources: ToolResources
        )
    {
        self.testEntries = testEntries
        self.buildArtifacts = buildArtifacts
        self.environment = environment
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.toolResources = toolResources
        self.bucketId = Bucket.generateBucketId(
            testEntries: testEntries,
            buildArtifacts: buildArtifacts,
            environment: environment,
            simulatorSettings: simulatorSettings,
            testDestination: testDestination,
            toolResources: toolResources
        )
    }
    
    private static func generateBucketId(
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        environment: [String: String],
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        toolResources: ToolResources
        ) -> String
    {
        
        let tests: String = testEntries.map { $0.testName }.sorted().joined()
            + testDestination.destinationString
            + buildArtifacts.appBundle.description + buildArtifacts.runner.description + buildArtifacts.xcTestBundle.description
            + buildArtifacts.additionalApplicationBundles.map { $0.description }.sorted().joined()
            + environment.map { "\($0)=\($1)" }.sorted().joined()
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
