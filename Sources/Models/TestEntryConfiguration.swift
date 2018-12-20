import Foundation

public struct TestEntryConfiguration: Codable, CustomStringConvertible, Hashable {
    public let testEntry: TestEntry
    public let buildArtifacts: BuildArtifacts
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior

    public init(
        testEntry: TestEntry,
        buildArtifacts: BuildArtifacts,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior)
    {
        self.testEntry = testEntry
        self.buildArtifacts = buildArtifacts
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
    }
    
    public var description: String {
        return "<\(type(of: self)): \(testEntry) \(testDestination)>"
    }
    
    public static func createMatrix(
        testEntries: [TestEntry],
        buildArtifacts: BuildArtifacts,
        testDestinations: [TestDestination],
        testExecutionBehavior: TestExecutionBehavior)
        -> [TestEntryConfiguration]
    {
        return testDestinations.flatMap { (testDestination: TestDestination) -> [TestEntryConfiguration] in
            testEntries.map { (testEntry: TestEntry) -> TestEntryConfiguration in
                TestEntryConfiguration(
                    testEntry: testEntry,
                    buildArtifacts: buildArtifacts,
                    testDestination: testDestination,
                    testExecutionBehavior: testExecutionBehavior
                )
            }
        }
    }
}
