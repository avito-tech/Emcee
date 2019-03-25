import Extensions
import Foundation
import Logging
import Models

public final class TestEntryConfigurationGenerator {
    private let validatedEnteries: [TestToRun: [TestEntry]]
    private let testArgEntries: [TestArgFile.Entry]
    private let buildArtifacts: BuildArtifacts

    public init(
        validatedEnteries: [TestToRun: [TestEntry]],
        testArgEntries: [TestArgFile.Entry],
        buildArtifacts: BuildArtifacts
        )
    {
        self.validatedEnteries = validatedEnteries
        self.testArgEntries = testArgEntries
        self.buildArtifacts = buildArtifacts
    }
    
    public func createTestEntryConfigurations() -> [TestEntryConfiguration] {
        Logger.debug("Preparing test entry configurations for tests: \(testArgEntries.map { $0.testToRun })")
        let testArgFileEntryConfigurations = testArgEntries.flatMap { testArgFileEntry -> [TestEntryConfiguration] in
            let testEntries = map(testsToRun: [testArgFileEntry.testToRun])
            return testEntries.map { testEntry in
                TestEntryConfiguration(
                    testEntry: testEntry,
                    buildArtifacts: buildArtifacts,
                    testDestination: testArgFileEntry.testDestination,
                    testExecutionBehavior: TestExecutionBehavior(
                        environment: testArgFileEntry.environment,
                        numberOfRetries: testArgFileEntry.numberOfRetries
                    )
                )
            }
        }
        return testArgFileEntryConfigurations
    }
    
    private func map(testsToRun: [TestToRun]) -> [TestEntry] {
        return validatedEnteries
            .filter { testsToRun.contains($0.key) }
            .flatMap { $0.value }
    }
}

