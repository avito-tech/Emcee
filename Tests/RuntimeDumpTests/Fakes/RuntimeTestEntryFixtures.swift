import RuntimeDump

class RuntimeTestEntryFixtures {
    static func entry(
        className: String = "Class",
        testMethods: [String] = ["testMethod"]
    ) -> RuntimeTestEntry {
        return RuntimeTestEntry(
            className: className,
            path: "",
            testMethods: testMethods,
            caseId: nil,
            tags: []
        )
    }
}
