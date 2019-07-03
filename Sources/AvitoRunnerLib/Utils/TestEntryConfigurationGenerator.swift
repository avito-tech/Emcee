import Extensions
import Foundation
import Logging
import Models

public final class TestEntryConfigurationGenerator {
    private let validatedEnteries: [ValidatedTestEntry]
    private let testArgEntries: [TestArgFile.Entry]

    public init(
        validatedEnteries: [ValidatedTestEntry],
        testArgEntries: [TestArgFile.Entry]
    ) {
        self.validatedEnteries = validatedEnteries
        self.testArgEntries = testArgEntries
    }
    
    public func createTestEntryConfigurations() -> [TestEntryConfiguration] {
        Logger.debug("Preparing test entry configurations for tests: \(testArgEntries.map { $0.testToRun })")
        let testArgFileEntryConfigurations = testArgEntries.flatMap { testArgFileEntry -> [TestEntryConfiguration] in
            let testEntries = validatedEntriesForArgFileEntry(argFileEntry: testArgFileEntry)
            return testEntries.map { testEntry in
                TestEntryConfiguration(
                    testEntry: testEntry,
                    buildArtifacts: testArgFileEntry.buildArtifacts,
                    testDestination: testArgFileEntry.testDestination,
                    testExecutionBehavior: TestExecutionBehavior(
                        environment: testArgFileEntry.environment,
                        numberOfRetries: testArgFileEntry.numberOfRetries
                    ),
                    testType: testArgFileEntry.testType,
                    toolchainConfiguration: testArgFileEntry.toolchainConfiguration
                )
            }
        }
        return testArgFileEntryConfigurations
    }

    private func validatedEntriesForArgFileEntry(argFileEntry: TestArgFile.Entry) -> [TestEntry] {
        return validatedEnteries
            .filter { argFileEntry.testToRun == $0.testToRun && argFileEntry.buildArtifacts == $0.buildArtifacts }
            .flatMap { $0.testEntries }
    }
}

