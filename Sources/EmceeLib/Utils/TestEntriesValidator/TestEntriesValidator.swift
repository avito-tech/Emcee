import EventBus
import Models
import RuntimeDump
import SimulatorPool
import Logging
import ResourceLocationResolver
import TemporaryStuff

public final class TestEntriesValidator {

    enum TestEntriesValidatorError: Error, CustomStringConvertible {
        case runtimeDumpMissesAppBundle

        public var description: String {
            switch self {
            case .runtimeDumpMissesAppBundle:
                return "Pass buildArtifacts.app inside --test-arg-file for each appTest"
            }
        }
    }

    private let validatorConfiguration: TestEntriesValidatorConfiguration
    private let runtimeTestQuerier: RuntimeTestQuerier
    private let transformer = TestToRunIntoTestEntryTransformer()

    public init(
        validatorConfiguration: TestEntriesValidatorConfiguration,
        runtimeTestQuerier: RuntimeTestQuerier
    ) {
        self.validatorConfiguration = validatorConfiguration
        self.runtimeTestQuerier = runtimeTestQuerier
    }
    
    public func validatedTestEntries(
        intermediateResult: (TestArgFile.Entry, [ValidatedTestEntry]) throws -> ()
    ) throws -> [ValidatedTestEntry] {
        var result = [ValidatedTestEntry]()
        
        for testArgFileEntry in validatorConfiguration.testArgFileEntries {
            let validatedTestEntries = try self.validatedTestEntries(testArgFileEntry: testArgFileEntry)
            try intermediateResult(testArgFileEntry, validatedTestEntries)
            result.append(contentsOf: validatedTestEntries)
        }
        
        return result
    }

    private func validatedTestEntries(
        testArgFileEntry: TestArgFile.Entry
    ) throws -> [ValidatedTestEntry] {
        let runtimeDumpMode = try determineDumpMode(
            buildArtifacts: testArgFileEntry.buildArtifacts,
            testArgFileEntry: testArgFileEntry
        )

        let runtimeDumpConfiguration = RuntimeDumpConfiguration(
            testRunnerTool: validatorConfiguration.testRunnerTool,
            xcTestBundleLocation: testArgFileEntry.buildArtifacts.xcTestBundle.location,
            runtimeDumpMode: runtimeDumpMode,
            testDestination: testArgFileEntry.testDestination,
            testsToValidate: testArgFileEntry.testsToRun,
            developerDir: testArgFileEntry.toolchainConfiguration.developerDir
        )

        return try transformer.transform(
            runtimeQueryResult: try runtimeTestQuerier.queryRuntime(
                configuration: runtimeDumpConfiguration
            ),
            buildArtifacts: testArgFileEntry.buildArtifacts
        )
    }

    private func determineDumpMode(
        buildArtifacts: BuildArtifacts,
        testArgFileEntry: TestArgFile.Entry
    ) throws -> RuntimeDumpMode {
        if testArgFileEntry.buildArtifacts.xcTestBundle.runtimeDumpKind == .logicTest {
            return .logicTest
        }

        guard let appBundle = buildArtifacts.appBundle else {
            throw TestEntriesValidatorError.runtimeDumpMissesAppBundle
        }

        return .appTest(
            RuntimeDumpApplicationTestSupport(
                appBundle: appBundle,
                simulatorControlTool: validatorConfiguration.simulatorControlTool
            )
        )
    }
}
