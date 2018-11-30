import Foundation

public struct TestEntryConfiguration: Codable, CustomStringConvertible, Hashable {
    public let testEntry: TestEntry
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior
    public let buildArtifacts: BuildArtifacts

    public init(
        testEntry: TestEntry,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        buildArtifacts: BuildArtifacts)
    {
        self.testEntry = testEntry
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.buildArtifacts = buildArtifacts
    }
    
    public var description: String {
        return "<\(type(of: self)): \(testEntry) \(testDestination)>"
    }
    
    public static func createMatrix(
        testEntries: [TestEntry],
        testDestinations: [TestDestination],
        testExecutionBehavior: TestExecutionBehavior,
        buildArtifacts: BuildArtifacts
        ) -> [TestEntryConfiguration]
    {
        return testDestinations.flatMap { (testDestination: TestDestination) -> [TestEntryConfiguration] in
            testEntries.map { (testEntry: TestEntry) -> TestEntryConfiguration in
                TestEntryConfiguration(
                    testEntry: testEntry,
                    testDestination: testDestination,
                    testExecutionBehavior: testExecutionBehavior,
                    buildArtifacts: buildArtifacts
                )
            }
        }
    }
}
