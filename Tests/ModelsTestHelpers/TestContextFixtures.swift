import Foundation
import Models

public final class TestContextFixtures {
    public var environment: [String: String]
    public var simulatorInfo: SimulatorInfo
    
    public init(
        environment: [String: String] = [:],
        simulatorInfo: SimulatorInfo = SimulatorInfo(
            simulatorUuid: nil,
            simulatorSetPath: "",
            testDestination: TestDestinationFixtures.testDestination
        )
    ) {
        self.environment = environment
        self.simulatorInfo = simulatorInfo
    }
    
    public var testContext: TestContext {
        return TestContext(environment: environment, simulatorInfo: simulatorInfo)
    }
}
