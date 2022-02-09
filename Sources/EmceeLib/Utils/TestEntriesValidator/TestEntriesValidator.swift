import EventBus
import EmceeLogging
import MetricsExtensions
import ResourceLocationResolver
import RunnerModels
import SimulatorPool
import Tmp
import TestArgFile
import TestDiscovery

public final class TestEntriesValidator {
    private let remoteCache: RuntimeDumpRemoteCache
    private let testArgFileEntries: [TestArgFileEntry]
    private let testDiscoveryQuerier: TestDiscoveryQuerier
    private let analyticsConfiguration: AnalyticsConfiguration
    private let transformer = TestToRunIntoTestEntryTransformer()

    public init(
        remoteCache: RuntimeDumpRemoteCache,
        testArgFileEntries: [TestArgFileEntry],
        testDiscoveryQuerier: TestDiscoveryQuerier,
        analyticsConfiguration: AnalyticsConfiguration
    ) {
        self.remoteCache = remoteCache
        self.testArgFileEntries = testArgFileEntries
        self.testDiscoveryQuerier = testDiscoveryQuerier
        self.analyticsConfiguration = analyticsConfiguration
    }
    
    public func validatedTestEntries(
        logger: ContextualLogger,
        intermediateResult: (TestArgFileEntry, [ValidatedTestEntry]) throws -> ()
    ) throws -> [ValidatedTestEntry] {
        var result = [ValidatedTestEntry]()
        
        for testArgFileEntry in testArgFileEntries {
            let validatedTestEntries = try self.validatedTestEntries(
                logger: logger,
                testArgFileEntry: testArgFileEntry
            )
            try intermediateResult(testArgFileEntry, validatedTestEntries)
            result.append(contentsOf: validatedTestEntries)
        }
        
        return result
    }

    private func validatedTestEntries(
        logger: ContextualLogger,
        testArgFileEntry: TestArgFileEntry
    ) throws -> [ValidatedTestEntry] {
        let configuration = TestDiscoveryConfiguration(
            analyticsConfiguration: analyticsConfiguration,
            developerDir: testArgFileEntry.developerDir,
            pluginLocations: testArgFileEntry.pluginLocations,
            testDiscoveryMode: try TestDiscoveryModeDeterminer.testDiscoveryMode(
                testArgFileEntry: testArgFileEntry
            ),
            simulatorOperationTimeouts: testArgFileEntry.simulatorOperationTimeouts,
            simulatorSettings: testArgFileEntry.simulatorSettings,
            simDeviceType: try testArgFileEntry.testDestination.simDeviceType(),
            simRuntime: try testArgFileEntry.testDestination.simRuntime(),
            testExecutionBehavior: TestExecutionBehavior(
                environment: testArgFileEntry.environment,
                userInsertedLibraries: testArgFileEntry.userInsertedLibraries,
                numberOfRetries: testArgFileEntry.numberOfRetries,
                testRetryMode: testArgFileEntry.testRetryMode,
                logCapturingMode: testArgFileEntry.logCapturingMode,
                runnerWasteCleanupPolicy: testArgFileEntry.runnerWasteCleanupPolicy
            ),
            testTimeoutConfiguration: testArgFileEntry.testTimeoutConfiguration,
            testAttachmentLifetime: testArgFileEntry.testAttachmentLifetime,
            testsToValidate: testArgFileEntry.testsToRun,
            xcTestBundleLocation: testArgFileEntry.buildArtifacts.xcTestBundle.location,
            remoteCache: remoteCache,
            logger: logger
        )

        return try transformer.transform(
            buildArtifacts: testArgFileEntry.buildArtifacts,
            testDiscoveryResult: try testDiscoveryQuerier.query(
                configuration: configuration
            )
        )
    }
}
