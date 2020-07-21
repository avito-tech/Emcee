import DeveloperDirModels
import Foundation
import RunnerModels
import SimulatorPoolModels
import SimulatorPoolTestHelpers

public final class TestContextFixtures {
    public var developerDir: DeveloperDir
    public var environment: [String: String]
    public var simulatorPath: URL
    public var simulatorUdid: UDID
    public var testDestination: TestDestination
    
    public init(
        developerDir: DeveloperDir = DeveloperDir.current,
        environment: [String: String] = [:],
        simulatorPath: URL = URL(fileURLWithPath: NSTemporaryDirectory()),
        simulatorUdid: UDID = UDID(value: "fixture_test_context_udid"),
        testDestination: TestDestination = TestDestinationFixtures.testDestination
    ) {
        self.developerDir = developerDir
        self.environment = environment
        self.simulatorPath = simulatorPath
        self.simulatorUdid = simulatorUdid
        self.testDestination = testDestination
    }
    
    public var testContext: TestContext {
        return TestContext(
            developerDir: developerDir,
            environment: environment,
            simulatorPath: simulatorPath,
            simulatorUdid: simulatorUdid,
            testDestination: testDestination
        )
    }
}
