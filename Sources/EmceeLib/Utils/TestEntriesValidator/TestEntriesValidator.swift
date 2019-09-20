import EventBus
import Models
import RuntimeDump
import SimulatorPool
import Logging
import ResourceLocationResolver
import TemporaryStuff

public final class TestEntriesValidator {

    enum `Error`: Swift.Error, CustomStringConvertible {
        case runtimeDumpMissesFbsimctl
        case runtimeDumpMissesAppBundle

        public var description: String {
            switch self {
            case .runtimeDumpMissesFbsimctl:
                return "No fbsimctl provided for application tests, pass --fbsimctl argument"
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
        let runtimeDumpApplicationTestSupport = try buildRuntimeDumpApplicationTestSupport(
            buildArtifacts: testArgFileEntry.buildArtifacts,
            testArgFileEntry: testArgFileEntry
        )

        let runtimeDumpConfiguration = RuntimeDumpConfiguration(
            testRunnerTool: validatorConfiguration.testRunnerTool,
            xcTestBundle: testArgFileEntry.buildArtifacts.xcTestBundle,
            applicationTestSupport: runtimeDumpApplicationTestSupport,
            testDestination: validatorConfiguration.testDestination,
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

    private func buildRuntimeDumpApplicationTestSupport(
        buildArtifacts: BuildArtifacts,
        testArgFileEntry: TestArgFile.Entry
    ) throws -> RuntimeDumpApplicationTestSupport? {
        let needToDumpApplicationTests = testArgFileEntry.buildArtifacts.xcTestBundle.runtimeDumpKind == .appTest
        
        guard needToDumpApplicationTests else { return nil }
        
        guard let simulatorControlTool = validatorConfiguration.simulatorControlTool else {
            throw Error.runtimeDumpMissesFbsimctl
        }
        
        guard let appBundle = buildArtifacts.appBundle else {
            throw Error.runtimeDumpMissesAppBundle
        }
        
        return RuntimeDumpApplicationTestSupport(
            appBundle: appBundle,
            simulatorControlTool: simulatorControlTool
        )
    }
}
