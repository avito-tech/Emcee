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
        return "<\((type(of: self))), \(simulatorControlTool), \(testRunnerTool)>"
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
        switch simulatorControlTool {
        case .fbsimctl(let fbsimctlLocation):
            try container.encode(fbsimctlLocation, forKey: .fbsimctl)
        }
    
        try container.encode(testRunnerTool, forKey: .testRunnerTool)
        switch testRunnerTool {
        case .fbxctest(let fbxctestLocation):
            try container.encode(fbxctestLocation, forKey: .fbxctest)
        }
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let simulatorControlTool = try container.decodeIfPresent(
            SimulatorControlTool.self,
            forKey: .simulatorControlTool
        ) ?? SimulatorControlTool.fbsimctl(
            try container.decode(FbsimctlLocation.self, forKey: .fbsimctl)
        )
        
        let testRunnerTool = try container.decodeIfPresent(
            TestRunnerTool.self,
            forKey: .testRunnerTool
        ) ?? TestRunnerTool.fbxctest(
            try container.decode(FbxctestLocation.self, forKey: .fbxctest)
        )
        
        self.init(
            simulatorControlTool: simulatorControlTool,
            testRunnerTool: testRunnerTool
        )
    }
}
