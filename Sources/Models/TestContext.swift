import Foundation

public final class TestContext: Codable, Hashable {
    public let developerDir: DeveloperDir
    /// Test execution environment.
    public let environment: [String: String]
    /// Simulator used to run tests.
    public let simulatorInfo: SimulatorInfo
    
    public init(
        developerDir: DeveloperDir,
        environment: [String: String],
        simulatorInfo: SimulatorInfo
    ) {
        self.developerDir = developerDir
        self.environment = environment
        self.simulatorInfo = simulatorInfo
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(developerDir)
        hasher.combine(environment)
        hasher.combine(simulatorInfo)
    }
    
    public static func == (left: TestContext, right: TestContext) -> Bool {
        return left.developerDir == right.developerDir
            && left.environment == right.environment
            && left.simulatorInfo == right.simulatorInfo
    }
}
