import Foundation

public struct Bucket: Codable, CustomStringConvertible, Hashable {
    public let bucketId: String
    public let testEntries: [TestEntry]
    public let testDestination: TestDestination
    
    public init(
        bucketId: String = UUID().uuidString,
        testEntries: [TestEntry],
        testDestination: TestDestination)
    {
        self.bucketId = bucketId
        self.testEntries = testEntries
        self.testDestination = testDestination
    }
    
    public var description: String {
        return "<\((type(of: self))) \(bucketId) \(testDestination), \(testEntries.count) tests>"
    }
    
    public var hashValue: Int {
        return bucketId.hashValue
    }
}
