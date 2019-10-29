import EventBus
import Models
import RuntimeDump
import SimulatorPool
import Logging
import ResourceLocationResolver
import TemporaryStuff

public final class TestEntriesValidator {
    private let testArgFileEntries: [TestArgFile.Entry]
    private let runtimeTestQuerier: RuntimeTestQuerier
    private let transformer = TestToRunIntoTestEntryTransformer()

    public init(
        testArgFileEntries: [TestArgFile.Entry],
        runtimeTestQuerier: RuntimeTestQuerier
    ) {
        self.testArgFileEntries = testArgFileEntries
        self.runtimeTestQuerier = runtimeTestQuerier
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
        let runtimeDumpConfiguration = RuntimeDumpConfiguration(
            developerDir: testArgFileEntry.toolchainConfiguration.developerDir,
            runtimeDumpMode: try RuntimeDumpModeDeterminer.runtimeDumpMode(
                testArgFileEntry: testArgFileEntry
            ),
            testDestination: testArgFileEntry.testDestination,
            testExecutionBehavior: TestExecutionBehavior(
                environment: testArgFileEntry.environment,
                numberOfRetries: testArgFileEntry.numberOfRetries
            ),
            testRunnerTool: testArgFileEntry.toolResources.testRunnerTool,
            testTimeoutConfiguration: testTimeoutConfigurationForRuntimeDump,
            testsToValidate: testArgFileEntry.testsToRun,
            xcTestBundleLocation: testArgFileEntry.buildArtifacts.xcTestBundle.location
        )

        return try transformer.transform(
            runtimeQueryResult: try runtimeTestQuerier.queryRuntime(
                configuration: runtimeDumpConfiguration
            ),
            buildArtifacts: testArgFileEntry.buildArtifacts
        )
    }
}
