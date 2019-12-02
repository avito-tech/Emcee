import Extensions
import Foundation
import Logging
import Models

public final class TestEntryConfigurationGenerator {
    private let validatedEntries: [ValidatedTestEntry]
    private let testArgFileEntry: TestArgFile.Entry

    public init(
        validatedEntries: [ValidatedTestEntry],
        testArgFileEntry: TestArgFile.Entry
    ) {
        self.validatedEntries = validatedEntries
        self.testArgFileEntry = testArgFileEntry
    }
    
    public func createTestEntryConfigurations() -> [TestEntryConfiguration] {
        Logger.debug("Preparing test entry configurations for \(testArgFileEntry.testsToRun.count) tests: \(testArgFileEntry.testsToRun)")
        
        let testArgFileEntryConfigurations = testArgFileEntry.testsToRun.flatMap { testToRun -> [TestEntryConfiguration] in
            let testEntries = testEntriesMatching(
                buildArtifacts: testArgFileEntry.buildArtifacts,
                testToRun: testToRun
            )
            return testEntries.map { testEntry -> TestEntryConfiguration in
                TestEntryConfiguration(
                    buildArtifacts: testArgFileEntry.buildArtifacts,
                    simulatorSettings: testArgFileEntry.simulatorSettings,
                    testDestination: testArgFileEntry.testDestination,
                    testEntry: testEntry,
                    testExecutionBehavior: TestExecutionBehavior(
                        environment: testArgFileEntry.environment,
                        numberOfRetries: testArgFileEntry.numberOfRetries
                    ),
                    testTimeoutConfiguration: testArgFileEntry.testTimeoutConfiguration,
                    testType: testArgFileEntry.testType,
                    toolResources: testArgFileEntry.toolResources,
                    toolchainConfiguration: testArgFileEntry.toolchainConfiguration
                )
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

