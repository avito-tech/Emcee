import Foundation

public final class TestContext: Codable, Hashable {
    /// Test execution environment.
    public let environment: [String: String]
    /// Simulator UUID used to run tests. Nil value likely means no simulator has been booted, e.g. runtime dump.
    public let simulatorInfo: SimulatorInfo
    /// Simulator type.
    public let testDestination: TestDestination
    
    public init(
        environment: [String: String],
        simulatorInfo: SimulatorInfo,
        testDestination: TestDestination
        )
    {
        self.environment = environment
        self.simulatorInfo = simulatorInfo
        self.testDestination = testDestination
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(environment)
        hasher.combine(simulatorInfo)
        hasher.combine(testDestination)
    }
    
    public static func == (left: TestContext, right: TestContext) -> Bool {
        return left.environment == right.environment
            && left.simulatorInfo == right.simulatorInfo
            && left.testDestination == right.testDestination
    }
}
