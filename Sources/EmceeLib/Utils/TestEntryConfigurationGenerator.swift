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
        Logger.debug("Preparing test entry configurations for tests: \(testArgEntries.flatMap { $0.testsToRun })")
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
            .filter { validatedTestEntry -> Bool in
                argFileEntry.testsToRun.contains(validatedTestEntry.testToRun)
                    && argFileEntry.buildArtifacts == validatedTestEntry.buildArtifacts
            }
            .flatMap { $0.testEntries }
    }
}

