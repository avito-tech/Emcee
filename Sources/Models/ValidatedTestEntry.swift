public final class ValidatedTestEntry: Equatable {
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

    public static func == (lhs: ValidatedTestEntry, rhs: ValidatedTestEntry) -> Bool {
        return lhs.testToRun == rhs.testToRun &&
            lhs.buildArtifacts == rhs.buildArtifacts &&
            lhs.testEntries == rhs.testEntries
    }
}
