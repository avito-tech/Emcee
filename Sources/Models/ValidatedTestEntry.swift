public final class ValidatedTestEntry: Hashable {
    public let testName: TestName
    public let testEntries : [TestEntry]
    public let buildArtifacts: BuildArtifacts

    public init(
        testName: TestName,
        testEntries : [TestEntry],
        buildArtifacts: BuildArtifacts
    ) {
        self.testName = testName
        self.testEntries = testEntries
        self.buildArtifacts = buildArtifacts
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(testName)
        hasher.combine(testEntries)
        hasher.combine(buildArtifacts)
    }

    public static func == (left: ValidatedTestEntry, right: ValidatedTestEntry) -> Bool {
        return left.testName == right.testName
            && left.buildArtifacts == right.buildArtifacts
            && left.testEntries == right.testEntries
    }
}
