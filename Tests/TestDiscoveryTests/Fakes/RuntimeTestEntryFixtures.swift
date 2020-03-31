import TestDiscovery

class DiscoveredTestEntryFixtures {
    static func entry(
        className: String = "Class",
        testMethods: [String] = ["testMethod"]
    ) -> DiscoveredTestEntry {
        return DiscoveredTestEntry(
            className: className,
            path: "",
            testMethods: testMethods,
            caseId: nil,
            tags: []
        )
    }
}
