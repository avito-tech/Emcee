import Foundation
import Models

public final class TestEntryConfigurationFixtures {
    public var testEntries = [TestEntry]()
    public var testDestination = TestDestinationFixtures.testDestination
    public var testExecutionBehavior = TestExecutionBehavior(numberOfRetries: 0)
    public var buildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    
    public init() {}
    
    public func add(testEntry: TestEntry) -> TestEntryConfigurationFixtures {
        testEntries.append(testEntry)
        return self
    }
    
    public func add(testEntries: [TestEntry]) -> TestEntryConfigurationFixtures {
        self.testEntries.append(contentsOf: testEntries)
        return self
    }
    
    public func with(testDestination: TestDestination) -> TestEntryConfigurationFixtures {
        self.testDestination = testDestination
        return self
    }
    
    public func with(testExecutionBehavior: TestExecutionBehavior) -> TestEntryConfigurationFixtures {
        self.testExecutionBehavior = testExecutionBehavior
        return self
    }
    
    public func with(buildArtifacts: BuildArtifacts) -> TestEntryConfigurationFixtures {
        self.buildArtifacts = buildArtifacts
        return self
    }
    
    public func testEntryConfigurations() -> [TestEntryConfiguration] {
        return testEntries.map {
            TestEntryConfiguration(
                testEntry: $0,
                testDestination: testDestination,
                testExecutionBehavior: testExecutionBehavior,
                buildArtifacts: buildArtifacts)
        }
    }
}
