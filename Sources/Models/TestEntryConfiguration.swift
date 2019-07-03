import Foundation

public struct TestEntryConfiguration: Codable, CustomStringConvertible, Hashable {
    public let testEntry: TestEntry
    public let buildArtifacts: BuildArtifacts
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior
    public let testType: TestType
    public let toolchainConfiguration: ToolchainConfiguration

    public init(
        testEntry: TestEntry,
        buildArtifacts: BuildArtifacts,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        testType: TestType,
        toolchainConfiguration: ToolchainConfiguration
    ) {
        self.testEntry = testEntry
        self.buildArtifacts = buildArtifacts
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.testType = testType
        self.toolchainConfiguration = toolchainConfiguration
    }
    
    public var description: String {
        return "<\(type(of: self)): \(testEntry) \(testType) \(testDestination)>"
    }
}
