import CommonTestModels

public protocol WithUpdatableTestEntries: WithTestEntries {
    func with(
        testEntries: [TestEntry]
    ) -> Self
}
