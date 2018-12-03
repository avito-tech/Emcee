import Extensions
import Foundation

public final class Bucket: Codable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let bucketId: String
    public let testEntries: [TestEntry]
    public let testDestination: TestDestination
    public let toolResources: ToolResources
    public let buildArtifacts: BuildArtifacts
    public let simulatorSettings: SimulatorSettings

    public init(
        testEntries: [TestEntry],
        testDestination: TestDestination,
        toolResources: ToolResources,
        buildArtifacts: BuildArtifacts,
        simulatorSettings: SimulatorSettings
        )
    {
        self.testEntries = testEntries
        self.testDestination = testDestination
        self.toolResources = toolResources
        self.buildArtifacts = buildArtifacts
        self.simulatorSettings = simulatorSettings
        self.bucketId = Bucket.generateBucketId(
            testEntries: testEntries,
            testDestination: testDestination,
            toolResources: toolResources,
            buildArtifacts: buildArtifacts,
            simulatorSettings: simulatorSettings
        )
    }
    
    private static func generateBucketId(
        testEntries: [TestEntry],
        testDestination: TestDestination,
        toolResources: ToolResources,
        buildArtifacts: BuildArtifacts,
        simulatorSettings: SimulatorSettings
        ) -> String
    {
        let tests: String = testEntries.map { $0.testName }.sorted().joined()
            + testDestination.destinationString
            + toolResources.fbsimctl.description + toolResources.fbxctest.description
            + buildArtifacts.appBundle.description + buildArtifacts.runner.description + buildArtifacts.xcTestBundle.description
            + buildArtifacts.additionalApplicationBundles.map { $0.description }.sorted().joined()
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
