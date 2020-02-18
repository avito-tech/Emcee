import Foundation
import SimulatorPoolModels

public struct ToolResources: Codable, Hashable, CustomStringConvertible {
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

    public var description: String {
        return "<\((type(of: self))), simulatorControlTool: \(simulatorControlTool), testRunnerTool: \(testRunnerTool)>"
    }
}
