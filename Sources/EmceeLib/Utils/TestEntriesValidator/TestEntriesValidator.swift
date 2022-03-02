import AppleTestModels
import CommonTestModels
import EventBus
import EmceeLogging
import MetricsExtensions
import ResourceLocationResolver
import SimulatorPool
import Tmp
import TestArgFile
import TestDiscovery

public final class TestEntriesValidator {
    private let remoteCache: RuntimeDumpRemoteCache
    private let testArgFileEntries: [TestArgFileEntry]
    private let testDiscoveryQuerier: AppleTestDiscoverer
    private let analyticsConfiguration: AnalyticsConfiguration
    private let transformer = TestToRunIntoTestEntryTransformer()

    public init(
        remoteCache: RuntimeDumpRemoteCache,
        testArgFileEntries: [TestArgFileEntry],
        testDiscoveryQuerier: AppleTestDiscoverer,
        analyticsConfiguration: AnalyticsConfiguration
    ) {
        self.remoteCache = remoteCache
        self.testArgFileEntries = testArgFileEntries
        self.testDiscoveryQuerier = testDiscoveryQuerier
        self.analyticsConfiguration = analyticsConfiguration
    }
    
    public func validatedTestEntries(
        intermediateResult: (TestArgFileEntry, [ValidatedTestEntry]) throws -> ()
    ) throws -> [ValidatedTestEntry] {
        var result = [ValidatedTestEntry]()
        
        for testArgFileEntry in testArgFileEntries {
            let validatedTestEntries = try self.validatedTestEntries(
                testArgFileEntry: testArgFileEntry
            )
            try intermediateResult(testArgFileEntry, validatedTestEntries)
            result.append(contentsOf: validatedTestEntries)
        }
        
        return result
    }

    private func validatedTestEntries(
        testArgFileEntry: TestArgFileEntry
    ) throws -> [ValidatedTestEntry] {
        let configuration = AppleTestDiscoveryConfiguration(
            analyticsConfiguration: analyticsConfiguration,
            remoteCache: remoteCache,
            testsToValidate: testArgFileEntry.testsToRun,
            testDiscoveryMode: try TestDiscoveryModeDeterminer.testDiscoveryMode(
                testArgFileEntry: testArgFileEntry
            ),
            testConfiguration: try testArgFileEntry.appleTestConfiguration()
        )

        return try transformer.transform(
            buildArtifacts: testArgFileEntry.buildArtifacts,
            testDiscoveryResult: try testDiscoveryQuerier.query(
                configuration: configuration
            )
        )
    }
}
