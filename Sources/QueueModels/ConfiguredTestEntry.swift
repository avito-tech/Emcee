import CommonTestModels

public final class ConfiguredTestEntry: Codable, CustomStringConvertible, Hashable {
    public let testEntry: TestEntry
    public let testEntryConfiguration: TestEntryConfiguration
    
    public init(
        testEntry: TestEntry,
        testEntryConfiguration: TestEntryConfiguration
    ) {
        self.testEntry = testEntry
        self.testEntryConfiguration = testEntryConfiguration
    }
    
    public var description: String {
        "\(testEntry) configuration: \(testEntryConfiguration)"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(testEntry)
        hasher.combine(testEntryConfiguration)
    }
    
    public static func == (lhs: ConfiguredTestEntry, rhs: ConfiguredTestEntry) -> Bool {
        return true
        && lhs.testEntry == rhs.testEntry
        && lhs.testEntryConfiguration == rhs.testEntryConfiguration
    }
}
