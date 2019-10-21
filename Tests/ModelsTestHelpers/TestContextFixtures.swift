import Foundation
import Models

public final class TestContextFixtures {
    public var developerDir: DeveloperDir
    public var environment: [String: String]
    public var simulatorInfo: SimulatorInfo
    
    public init(
        developerDir: DeveloperDir = DeveloperDir.current,
        environment: [String: String] = [:],
        simulatorInfo: SimulatorInfo = SimulatorInfo(
            simulatorUuid: nil,
            simulatorSetPath: "",
            testDestination: TestDestinationFixtures.testDestination
        )
    ) {
        self.developerDir = developerDir
        self.environment = environment
        self.simulatorInfo = simulatorInfo
    }
    
    public var testContext: TestContext {
        return TestContext(
            developerDir: developerDir,
            environment: environment,
            simulatorInfo: simulatorInfo
        )
    }
}
