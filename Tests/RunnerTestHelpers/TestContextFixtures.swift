import DeveloperDirModels
import Foundation
import PathLib
import RunnerModels
import SimulatorPoolModels
import SimulatorPoolTestHelpers

public final class TestContextFixtures {
    public var contextId: String
    public var developerDir: DeveloperDir
    public var environment: [String: String]
    public var userInsertedLibraries: [String]
    public var simulatorPath: AbsolutePath
    public var simulatorUdid: UDID
    public var simRuntime: SimRuntime
    public var simDeviceType: SimDeviceType
    public var testRunnerWorkingDirectory: AbsolutePath
    public var testsWorkingDirectory: AbsolutePath
    
    public init(
        contextId: String = UUID().uuidString,
        developerDir: DeveloperDir = DeveloperDir.current,
        environment: [String: String] = [:],
        userInsertedLibraries: [String] = [],
        simulatorPath: AbsolutePath = AbsolutePath(NSTemporaryDirectory()),
        simulatorUdid: UDID = UDID(value: "fixture_test_context_udid"),
        simRuntime: SimRuntime = SimRuntimeFixture.fixture(),
        simDeviceType: SimDeviceType = SimDeviceTypeFixture.fixture(),
        testRunnerWorkingDirectory: AbsolutePath = AbsolutePath(NSTemporaryDirectory()),
        testsWorkingDirectory: AbsolutePath = AbsolutePath(NSTemporaryDirectory())
    ) {
        self.contextId = contextId
        self.developerDir = developerDir
        self.environment = environment
        self.userInsertedLibraries = userInsertedLibraries
        self.simulatorPath = simulatorPath
        self.simulatorUdid = simulatorUdid
        self.simRuntime = simRuntime
        self.simDeviceType = simDeviceType
        self.testRunnerWorkingDirectory = testRunnerWorkingDirectory
        self.testsWorkingDirectory = testsWorkingDirectory
    }
    
    public var testContext: AppleTestContext {
        return AppleTestContext(
            contextId: contextId,
            developerDir: developerDir,
            environment: environment,
            userInsertedLibraries: userInsertedLibraries,
            simulator: Simulator(
                simDeviceType: simDeviceType,
                simRuntime: simRuntime,
                udid: simulatorUdid,
                path: simulatorPath
            ),
            testRunnerWorkingDirectory: testRunnerWorkingDirectory,
            testsWorkingDirectory: testsWorkingDirectory,
            testAttachmentLifetime: .deleteOnSuccess
        )
    }
}
