import Foundation
import QueueModels
import QueueModelsTestHelpers
import RunnerModels
import RunnerTestHelpers

func createTestEntryConfigurations(count: UInt) -> [TestEntryConfiguration] {
    let testEntries = (0..<count).reduce(into: [TestEntry]()) { result, index in
        result.append(TestEntryFixtures.testEntry(className: "class", methodName: "testMethod\(index)"))
    }
    return TestEntryConfigurationFixtures().add(
        testEntries: testEntries
    ).testEntryConfigurations()
}
