import BuildArtifacts
import Foundation
import Logging
import QueueModels
import RunnerModels
import TestArgFile
import TestDiscovery

public final class TestEntryConfigurationGenerator {
    private let validatedEntries: [ValidatedTestEntry]
    private let testArgFileEntry: TestArgFileEntry
    private let persistentMetricsJobId: String

    public init(
        validatedEntries: [ValidatedTestEntry],
        testArgFileEntry: TestArgFileEntry,
        persistentMetricsJobId: String
    ) {
        self.validatedEntries = validatedEntries
        self.testArgFileEntry = testArgFileEntry
        self.persistentMetricsJobId = persistentMetricsJobId
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
                    developerDir: testArgFileEntry.developerDir,
                    pluginLocations: testArgFileEntry.pluginLocations,
                    simulatorControlTool: testArgFileEntry.simulatorControlTool,
                    simulatorOperationTimeouts: testArgFileEntry.simulatorOperationTimeouts,
                    simulatorSettings: testArgFileEntry.simulatorSettings,
                    testDestination: testArgFileEntry.testDestination,
                    testEntry: testEntry,
                    testExecutionBehavior: TestExecutionBehavior(
                        environment: testArgFileEntry.environment,
                        numberOfRetries: testArgFileEntry.numberOfRetries
                    ),
                    testRunnerTool: testArgFileEntry.testRunnerTool,
                    testTimeoutConfiguration: testArgFileEntry.testTimeoutConfiguration,
                    testType: testArgFileEntry.testType,
                    workerCapabilityRequirements: testArgFileEntry.workerCapabilityRequirements,
                    persistentMetricsJobId: persistentMetricsJobId
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
                case .allDiscoveredTests:
                    return true
                case .testName(let testName):
                    return testName == $0.testName
                }
            }
            .flatMap { $0.testEntries }
    }
}

