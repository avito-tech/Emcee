import AppleTestModels
import BuildArtifacts
import CommonTestModels
import Foundation
import EmceeLogging
import MetricsExtensions
import QueueModels
import TestArgFile
import TestDiscovery

public final class SimilarlyConfiguredTestEntryGenerator {
    private let analyticsConfiguration: AnalyticsConfiguration
    private let validatedEntries: [ValidatedTestEntry]
    private let testArgFileEntry: TestArgFileEntry
    private let logger: ContextualLogger

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        validatedEntries: [ValidatedTestEntry],
        testArgFileEntry: TestArgFileEntry,
        logger: ContextualLogger
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.validatedEntries = validatedEntries
        self.testArgFileEntry = testArgFileEntry
        self.logger = logger
    }
    
    public func createSimilarlyConfiguredTestEntries() throws -> SimilarlyConfiguredTestEntries {
        logger.trace("Preparing configured test entries for \(testArgFileEntry.testsToRun.count) tests: \(testArgFileEntry.testsToRun)")
        
        let testEntryConfiguration = TestEntryConfiguration(
            analyticsConfiguration: analyticsConfiguration,
            testConfigurationContainer: .appleTest(
                try testArgFileEntry.appleTestConfiguration()
            ),
            workerCapabilityRequirements: testArgFileEntry.workerCapabilityRequirements
        )
        
        let testEntries = testArgFileEntry.testsToRun.flatMap { (testToRun: TestToRun) -> [TestEntry] in
            testEntriesMatching(
                buildArtifacts: testArgFileEntry.buildArtifacts,
                testToRun: testToRun
            )
        }
        
        let similarlyConfiguredTestEntries = SimilarlyConfiguredTestEntries(
            testEntries: testEntries,
            testEntryConfiguration: testEntryConfiguration
        )
        return similarlyConfiguredTestEntries
    }

    private func testEntriesMatching(
        buildArtifacts: AppleBuildArtifacts,
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

