import Foundation

public final class ToolResources: Codable, Hashable, CustomStringConvertible {
    /// A tool to control simulators.
    public let simulatorControlTool: SimulatorControlTool
    
    /// A tool for executing tests.
    public let testRunnerTool: TestRunnerTool
    
    public init(
        simulatorControlTool: SimulatorControlTool,
        testRunnerTool: TestRunnerTool
    ) {
        self.simulatorControlTool = simulatorControlTool
        self.testRunnerTool = testRunnerTool
    }
    
    public static func == (left: ToolResources, right: ToolResources) -> Bool {
        return left.simulatorControlTool == right.simulatorControlTool
            && left.testRunnerTool == right.testRunnerTool
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(simulatorControlTool)
        hasher.combine(testRunnerTool)
    }
    
    public var description: String {
        return "<\((type(of: self))), simulatorControlTool: \(simulatorControlTool), testRunnerTool: \(testRunnerTool)>"
    }
    
    // MARK: - TODO: remove custom Encodable & Decodable, left for backwards compatibility
    
    private enum CodingKeys: String, CodingKey {
        case simulatorControlTool
        case testRunnerTool
        case fbsimctl
        case fbxctest
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(simulatorControlTool, forKey: .simulatorControlTool)
        try container.encode(testRunnerTool, forKey: .testRunnerTool)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let simulatorControlTool = try container.decode(
            SimulatorControlTool.self,
            forKey: .simulatorControlTool
        )
        
        let testRunnerTool = try container.decode(
            TestRunnerTool.self,
            forKey: .testRunnerTool
        )

        self.init(
            simulatorControlTool: simulatorControlTool,
            testRunnerTool: testRunnerTool
        )
    }
}
