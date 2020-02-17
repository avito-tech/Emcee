import BuildArtifacts
import Models

public struct ValidatedTestEntry: Hashable {
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
}
