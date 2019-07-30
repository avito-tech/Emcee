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
        let testsToRun = testArgEntries.flatMap { $0.testsToRun }
        Logger.debug("Preparing test entry configurations for \(testsToRun.count) tests: \(testsToRun)")
        
        let testArgFileEntryConfigurations = testArgEntries.flatMap { testArgFileEntry -> [TestEntryConfiguration] in
            return testArgFileEntry.testsToRun.flatMap { testToRun -> [TestEntryConfiguration] in
                let testEntries = testEntriesMatching(
                    buildArtifacts: testArgFileEntry.buildArtifacts,
                    testToRun: testToRun
                )
                return testEntries.map { testEntry -> TestEntryConfiguration in
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
        }
        return testArgFileEntryConfigurations
    }

    private func testEntriesMatching(
        buildArtifacts: BuildArtifacts,
        testToRun: TestToRun
    ) -> [TestEntry] {
        return validatedEnteries
            .filter { validatedTestEntry -> Bool in
                testToRun == validatedTestEntry.testToRun && buildArtifacts == validatedTestEntry.buildArtifacts
            }
            .flatMap { $0.testEntries }
    }
}

