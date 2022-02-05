import BuildArtifacts
import RunnerModels

public struct ValidatedTestEntry: Hashable {
    public let testName: TestName
    public let testEntries : [TestEntry]
    public let buildArtifacts: AppleBuildArtifacts

    public init(
        testName: TestName,
        testEntries : [TestEntry],
        buildArtifacts: AppleBuildArtifacts
    ) {
        self.testName = testName
        self.testEntries = testEntries
        self.buildArtifacts = buildArtifacts
    }
}
