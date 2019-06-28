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

    public init(
        validatorConfiguration: TestEntriesValidatorConfiguration,
        runtimeTestQuerier: RuntimeTestQuerier
    ) {
        self.validatorConfiguration = validatorConfiguration
        self.runtimeTestQuerier = runtimeTestQuerier
    }
    
    public func validatedTestEntries() throws -> [ValidatedTestEntry] {
        let entriesPerBuildArtifact = Dictionary(grouping: validatorConfiguration.testEntries) { $0.buildArtifacts }

        var result = [ValidatedTestEntry]()
        for (buildArtifacts, testEntries)  in entriesPerBuildArtifact {
            result.append(
                contentsOf: try validatedTestEntriesForBuildArtifacts(
                    buildArtifacts: buildArtifacts,
                    testEntries: testEntries
                )
            )
        }

        return result
    }

    private func validatedTestEntriesForBuildArtifacts(
        buildArtifacts: BuildArtifacts,
        testEntries: [TestArgFile.Entry]
    ) throws -> [ValidatedTestEntry] {
        let runtimeDumpApplicationTestSupport = try buildRuntimeDumpApplicationTestSupport(
            buildArtifacts: buildArtifacts, testEntries: testEntries
        )

        let runtimeDumpConfiguration = RuntimeDumpConfiguration(
            fbxctest: validatorConfiguration.fbxctest,
            xcTestBundle: buildArtifacts.xcTestBundle,
            applicationTestSupport: runtimeDumpApplicationTestSupport,
            testDestination: validatorConfiguration.testDestination,
            testsToRun: testEntries.map { $0.testToRun }
        )

        let runtimeQueryResult = try runtimeTestQuerier.queryRuntime(configuration: runtimeDumpConfiguration)
        let transformer = TestToRunIntoTestEntryTransformer(testsToRun: runtimeDumpConfiguration.testsToRun)
        return try transformer.transform(
            runtimeQueryResult: runtimeQueryResult,
            buildArtifacts: buildArtifacts
        )
    }

    private func needToDumpApplicationTests(testEntries: [TestArgFile.Entry]) -> Bool {
        for testEntry in testEntries {
            if testEntry.buildArtifacts.xcTestBundle.runtimeDumpKind == .appTest {
                return true
            }
        }

        return false
    }

    private func buildRuntimeDumpApplicationTestSupport(
        buildArtifacts: BuildArtifacts,
        testEntries: [TestArgFile.Entry]
    ) throws -> RuntimeDumpApplicationTestSupport? {
        if needToDumpApplicationTests(testEntries: testEntries) {
            guard let fbsimctl = validatorConfiguration.fbsimctl else {
                throw Error.runtimeDumpMissesFbsimctl
            }

            guard let appBundle = buildArtifacts.appBundle else {
                throw Error.runtimeDumpMissesAppBundle
            }

            return RuntimeDumpApplicationTestSupport(appBundle: appBundle, fbsimctl: fbsimctl)
        }

        return nil
    }
}
