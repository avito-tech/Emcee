public final class ValidatedTestEntry: Hashable {
    public let testToRun: TestToRun
    public let testEntries : [TestEntry]
    public let buildArtifacts: BuildArtifacts

    public init(
        testToRun: TestToRun,
        testEntries : [TestEntry],
        buildArtifacts: BuildArtifacts
    ) {
        self.testToRun = testToRun
        self.testEntries = testEntries
        self.buildArtifacts = buildArtifacts
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(testToRun)
        hasher.combine(testEntries)
        hasher.combine(buildArtifacts)
    }

    public static func == (lhs: ValidatedTestEntry, rhs: ValidatedTestEntry) -> Bool {
        return lhs.testToRun == rhs.testToRun &&
            lhs.buildArtifacts == rhs.buildArtifacts &&
            lhs.testEntries == rhs.testEntries
    }
}
