import CommonTestModels
import Foundation

public final class SimilarlyConfiguredTestEntries: Codable, CustomStringConvertible, Hashable {
    public let testEntries: [TestEntry]
    public let testEntryConfiguration: TestEntryConfiguration
    
    public init(
        testEntries: [TestEntry],
        testEntryConfiguration: TestEntryConfiguration
    ) {
        self.testEntries = testEntries
        self.testEntryConfiguration = testEntryConfiguration
    }
    
    public var configuredTestEntries: [ConfiguredTestEntry] {
        testEntries.map { testEntry in
            ConfiguredTestEntry(
                testEntry: testEntry,
                testEntryConfiguration: testEntryConfiguration
            )
        }
    }
    
    public var description: String {
        "\(testEntries.count) tests with configuration: \(testEntryConfiguration)"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(testEntries)
        hasher.combine(testEntryConfiguration)
    }
    
    public static func == (lhs: SimilarlyConfiguredTestEntries, rhs: SimilarlyConfiguredTestEntries) -> Bool {
        return true
        && lhs.testEntries == rhs.testEntries
        && lhs.testEntryConfiguration == rhs.testEntryConfiguration
    }
}
