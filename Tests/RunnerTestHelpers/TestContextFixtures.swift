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
    public var simulatorPath: AbsolutePath
    public var simulatorUdid: UDID
    public var testDestination: TestDestination
    public var testsWorkingDirectory: AbsolutePath
    
    public init(
        contextId: String = UUID().uuidString,
        developerDir: DeveloperDir = DeveloperDir.current,
        environment: [String: String] = [:],
        simulatorPath: AbsolutePath = AbsolutePath(NSTemporaryDirectory()),
        simulatorUdid: UDID = UDID(value: "fixture_test_context_udid"),
        testDestination: TestDestination = TestDestinationFixtures.testDestination,
        testsWorkingDirectory: AbsolutePath = AbsolutePath(NSTemporaryDirectory())
    ) {
        self.contextId = contextId
        self.developerDir = developerDir
        self.environment = environment
        self.simulatorPath = simulatorPath
        self.simulatorUdid = simulatorUdid
        self.testDestination = testDestination
        self.testsWorkingDirectory = testsWorkingDirectory
    }
    
    public var testContext: TestContext {
        return TestContext(
            contextId: contextId,
            developerDir: developerDir,
            environment: environment,
            simulatorPath: simulatorPath,
            simulatorUdid: simulatorUdid,
            testDestination: testDestination,
            testsWorkingDirectory: testsWorkingDirectory
        )
    }
}
