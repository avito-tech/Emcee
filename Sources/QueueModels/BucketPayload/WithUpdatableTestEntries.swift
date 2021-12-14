import Foundation
import RunnerModels

public protocol WithUpdatableTestEntries: WithTestEntries {
    func with(
        testEntries: [TestEntry]
    ) -> Self
}
