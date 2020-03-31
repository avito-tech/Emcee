import EventBus
import Logging
import Models
import ResourceLocationResolver
import SimulatorPool
import TemporaryStuff
import TestArgFile
import TestDiscovery

public final class TestEntriesValidator {
    private let testArgFileEntries: [TestArgFile.Entry]
    private let testDiscoveryQuerier: TestDiscoveryQuerier
    private let transformer = TestToRunIntoTestEntryTransformer()

    public init(
        testArgFileEntries: [TestArgFile.Entry],
        testDiscoveryQuerier: TestDiscoveryQuerier
    ) {
        self.testArgFileEntries = testArgFileEntries
        self.testDiscoveryQuerier = testDiscoveryQuerier
    }
    
    public func validatedTestEntries(
        intermediateResult: (TestArgFile.Entry, [ValidatedTestEntry]) throws -> ()
    ) throws -> [ValidatedTestEntry] {
        var result = [ValidatedTestEntry]()
        
        for testArgFileEntry in testArgFileEntries {
            let validatedTestEntries = try self.validatedTestEntries(testArgFileEntry: testArgFileEntry)
            try intermediateResult(testArgFileEntry, validatedTestEntries)
            result.append(contentsOf: validatedTestEntries)
        }
        
        return result
    }

    private func validatedTestEntries(
        testArgFileEntry: TestArgFile.Entry
    ) throws -> [ValidatedTestEntry] {
        let configuration = TestDiscoveryConfiguration(
            developerDir: testArgFileEntry.developerDir,
            pluginLocations: testArgFileEntry.pluginLocations,
            testDiscoveryMode: try TestDiscoveryModeDeterminer.testDiscoveryMode(
                testArgFileEntry: testArgFileEntry
            ),
            simulatorOperationTimeouts: testArgFileEntry.simulatorOperationTimeouts,
            simulatorSettings: testArgFileEntry.simulatorSettings,
            testDestination: testArgFileEntry.testDestination,
            testExecutionBehavior: TestExecutionBehavior(
                environment: testArgFileEntry.environment,
                numberOfRetries: testArgFileEntry.numberOfRetries
            ),
            testRunnerTool: testArgFileEntry.testRunnerTool,
            testTimeoutConfiguration: testTimeoutConfigurationForRuntimeDump,
            testsToValidate: testArgFileEntry.testsToRun,
            xcTestBundleLocation: testArgFileEntry.buildArtifacts.xcTestBundle.location
        )

        return try transformer.transform(
            buildArtifacts: testArgFileEntry.buildArtifacts,
            testDiscoveryResult: try testDiscoveryQuerier.query(
                configuration: configuration
            )
        )
    }
}
