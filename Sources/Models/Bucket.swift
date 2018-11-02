import Extensions
import Foundation

public class Bucket: Codable, CustomStringConvertible, Hashable {
    public let bucketId: String
    public let testEntries: [TestEntry]
    public let testDestination: TestDestination
    public let toolResources: ToolResources

    public init(
        testEntries: [TestEntry],
        testDestination: TestDestination,
        toolResources: ToolResources)
    {
        self.testEntries = testEntries
        self.testDestination = testDestination
        self.toolResources = toolResources
        self.bucketId = Bucket.generateBucketId(testEntries: testEntries, testDestination: testDestination)
    }
    
    private static func generateBucketId(
        testEntries: [TestEntry],
        testDestination: TestDestination)
        -> String
    {
        let tests = testEntries.map { $0.testName }.sorted().joined() + testDestination.destinationString
        do {
            return try tests.avito_sha256Hash(encoding: .utf8)
        } catch {
            preconditionFailure("Unable to generate bucket id as SHA256 from the following string: '\(tests)'")
        }
    }
    
    public var description: String {
        return "<\((type(of: self))) \(bucketId) \(testDestination), \(testEntries.count) tests>"
    }
    
    public var hashValue: Int {
        return bucketId.hashValue
    }
    
    public static func == (left: Bucket, right: Bucket) -> Bool {
        return left.bucketId == right.bucketId
    }
}
