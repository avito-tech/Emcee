import Foundation

public final class TestContext: Codable, Hashable {
    /// Test execution environment.
    public let environment: [String: String]
    /// Simulator UUID used to run tests. Nil value likely means no simulator has been booted, e.g. runtime dump.
    public let simulatorInfo: SimulatorInfo
    
    public init(
        environment: [String: String],
        simulatorInfo: SimulatorInfo
    ) {
        self.environment = environment
        self.simulatorInfo = simulatorInfo
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(environment)
        hasher.combine(simulatorInfo)
    }
    
    public static func == (left: TestContext, right: TestContext) -> Bool {
        return left.environment == right.environment
            && left.simulatorInfo == right.simulatorInfo
    }
}
