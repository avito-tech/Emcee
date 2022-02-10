import CommonTestModels
import CommonTestModelsTestHelpers
import Foundation
import QueueModels

public final class ConfiguredTestEntryFixture {
    public var testEntry: TestEntry
    public var testEntryConfiguration: TestEntryConfiguration
    
    public init(
        testEntry: TestEntry = TestEntryFixtures.testEntry(),
        testEntryConfiguration: TestEntryConfiguration = TestEntryConfigurationFixtures().testEntryConfiguration()
    ) {
        self.testEntry = testEntry
        self.testEntryConfiguration = testEntryConfiguration
    }
    
    public func with(testEntry: TestEntry) -> Self {
        self.testEntry = testEntry
        return self
    }
    
    public func with(testEntryConfiguration: TestEntryConfiguration) -> Self {
        self.testEntryConfiguration = testEntryConfiguration
        return self
    }
    
    public func build() -> ConfiguredTestEntry {
        ConfiguredTestEntry(
            testEntry: testEntry,
            testEntryConfiguration: testEntryConfiguration
        )
    }
}
