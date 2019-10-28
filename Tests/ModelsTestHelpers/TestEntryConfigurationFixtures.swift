import Foundation
import Models

public final class TestEntryConfigurationFixtures {
    public var testEntries = [TestEntry]()
    public var testDestination = TestDestinationFixtures.testDestination
    public var testExecutionBehavior = TestExecutionBehavior(environment: [:], numberOfRetries: 0)
    public var buildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    public var testType = TestType.uiTest
    public var toolResources: ToolResources = ToolResourcesFixtures.fakeToolResources()
    public var toolchainConfiguration = ToolchainConfiguration(developerDir: .current)
    
    public init() {}
    
    public func add(testEntry: TestEntry) -> Self {
        testEntries.append(testEntry)
        return self
    }
    
    public func add(testEntries: [TestEntry]) -> Self {
        self.testEntries.append(contentsOf: testEntries)
        return self
    }
    
    public func with(testDestination: TestDestination) -> Self {
        self.testDestination = testDestination
        return self
    }
    
    public func with(testExecutionBehavior: TestExecutionBehavior) -> Self {
        self.testExecutionBehavior = testExecutionBehavior
        return self
    }
    
    public func with(buildArtifacts: BuildArtifacts) -> Self {
        self.buildArtifacts = buildArtifacts
        return self
    }
    
    public func with(testType: TestType) -> Self {
        self.testType = testType
        return self
    }
    
    public func with(toolResources: ToolResources) -> Self {
        self.toolResources = toolResources
        return self
    }
    
    public func with(toolchainConfiguration: ToolchainConfiguration) -> Self {
        self.toolchainConfiguration = toolchainConfiguration
        return self
    }
    
    public func testEntryConfigurations() -> [TestEntryConfiguration] {
        return testEntries.map {
            TestEntryConfiguration(
                testEntry: $0,
                buildArtifacts: buildArtifacts,
                testDestination: testDestination,
                testExecutionBehavior: testExecutionBehavior,
                testType: testType,
                toolResources: ToolResourcesFixtures.fakeToolResources(),
                toolchainConfiguration: toolchainConfiguration
            )
        }
    }
}
