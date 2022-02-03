import DeveloperDirModels
import Foundation
import PathLib
import RunnerModels
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestDestination
import TestDestinationTestHelpers

public final class TestContextFixtures {
    public var contextId: String
    public var developerDir: DeveloperDir
    public var environment: [String: String]
    public var userInsertedLibraries: [String]
    public var simulatorPath: AbsolutePath
    public var simulatorUdid: UDID
    public var testDestination: TestDestination
    public var testRunnerWorkingDirectory: AbsolutePath
    public var testsWorkingDirectory: AbsolutePath
    
    public init(
        contextId: String = UUID().uuidString,
        developerDir: DeveloperDir = DeveloperDir.current,
        environment: [String: String] = [:],
        userInsertedLibraries: [String] = [],
        simulatorPath: AbsolutePath = AbsolutePath(NSTemporaryDirectory()),
        simulatorUdid: UDID = UDID(value: "fixture_test_context_udid"),
        testDestination: TestDestination = TestDestinationFixtures.iOSTestDestination,
        testRunnerWorkingDirectory: AbsolutePath = AbsolutePath(NSTemporaryDirectory()),
        testsWorkingDirectory: AbsolutePath = AbsolutePath(NSTemporaryDirectory())
    ) {
        self.contextId = contextId
        self.developerDir = developerDir
        self.environment = environment
        self.userInsertedLibraries = userInsertedLibraries
        self.simulatorPath = simulatorPath
        self.simulatorUdid = simulatorUdid
        self.testDestination = testDestination
        self.testRunnerWorkingDirectory = testRunnerWorkingDirectory
        self.testsWorkingDirectory = testsWorkingDirectory
    }
    
    public var testContext: TestContext {
        return TestContext(
            contextId: contextId,
            developerDir: developerDir,
            environment: environment,
            userInsertedLibraries: userInsertedLibraries,
            simulatorPath: simulatorPath,
            simulatorUdid: simulatorUdid,
            testDestination: testDestination,
            testRunnerWorkingDirectory: testRunnerWorkingDirectory,
            testsWorkingDirectory: testsWorkingDirectory,
            testAttachmentLifetime: .deleteOnSuccess
        )
    }
}
