import EventBus
import Models
import RuntimeDump
import SimulatorPool
import Logging
import ResourceLocationResolver
import TempFolder

public final class TestEntriesValidator {

    enum `Error`: Swift.Error, CustomStringConvertible {
        case runtimeDumpsMissesApplicationTestSupport

        public var description: String {
            switch self {
            case .runtimeDumpsMissesApplicationTestSupport:
                return "No application test support provided, pass --app and --fbsimctl arguments"
            }
        }
    }

    private let validatorConfiguration: TestEntriesValidatorConfiguration
    private let runtimeTestQuerier: RuntimeTestQuerier

    public init(
        validatorConfiguration: TestEntriesValidatorConfiguration,
        runtimeTestQuerier: RuntimeTestQuerier)
    {
        self.validatorConfiguration = validatorConfiguration
        self.runtimeTestQuerier = runtimeTestQuerier
    }
    
    public func validatedTestEntries() throws -> [TestToRun: [TestEntry]] {
        let needToDumpApplicationTests = neenToDumpApplicationTests(validatorConfiguration: validatorConfiguration)
        if needToDumpApplicationTests {
            guard validatorConfiguration.supportsApplicationTests else {
                throw Error.runtimeDumpsMissesApplicationTestSupport
            }
        }
        let runtimeDumpConfiguration = validatorConfigurationToRuntimeDumpConfiguration(
            validatorConfiguration: validatorConfiguration,
            needsApplicationTestSupport: needToDumpApplicationTests
        )

        let runtimeQueryResult = try runtimeTestQuerier.queryRuntime(configuration: runtimeDumpConfiguration)
        let transformer = TestToRunIntoTestEntryTransformer(testsToRun: runtimeDumpConfiguration.testsToRun)
        return try transformer.transform(runtimeQueryResult: runtimeQueryResult)
    }

    private func neenToDumpApplicationTests(validatorConfiguration: TestEntriesValidatorConfiguration) -> Bool {
        for testEntry in validatorConfiguration.testEntries {
            if testEntry.testType == .appTest {
                return true
            }
        }

        return false
    }

    private func validatorConfigurationToRuntimeDumpConfiguration(
        validatorConfiguration: TestEntriesValidatorConfiguration,
        needsApplicationTestSupport: Bool) -> RuntimeDumpConfiguration
    {
        return RuntimeDumpConfiguration(
            fbxctest: validatorConfiguration.fbxctest,
            xcTestBundle: validatorConfiguration.xcTestBundle,
            applicationTestSupport: needsApplicationTestSupport ? validatorConfiguration.applicationTestSupport: nil,
            testDestination: validatorConfiguration.testDestination,
            testsToRun: validatorConfiguration.testEntries.map { $0.testToRun }
        )
    }
}
