import CommonTestModels
import CommonTestModelsTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers

func createConfiguredTestEntries(
    count: UInt
) -> [ConfiguredTestEntry] {
    let testEntries = (0..<count).reduce(into: [TestEntry]()) { result, index in
        result.append(TestEntryFixtures.testEntry(className: "class", methodName: "testMethod\(index)"))
    }
    return testEntries.map { testEntry in
        ConfiguredTestEntry(
            testEntry: testEntry,
            testEntryConfiguration: TestEntryConfigurationFixtures().testEntryConfiguration()
        )
    }
}
