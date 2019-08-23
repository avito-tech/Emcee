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
}
