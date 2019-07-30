import Extensions
import Foundation
import Logging
import Models

public final class TestEntryConfigurationGenerator {
    private let validatedEntries: [ValidatedTestEntry]
    private let testArgEntries: [TestArgFile.Entry]

    public init(
        validatedEntries: [ValidatedTestEntry],
        testArgEntries: [TestArgFile.Entry]
    ) {
        self.validatedEntries = validatedEntries
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
        return validatedEntries
            .filter { buildArtifacts == $0.buildArtifacts }
            .filter {
                switch testToRun {
                case .allProvidedByRuntimeDump:
                    return true
                case .testName(let testName):
                    return testName == $0.testName
                }
            }
            .flatMap { $0.testEntries }
    }
}

