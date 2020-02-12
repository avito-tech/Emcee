import Foundation
import Models

public struct OnDemandSimulatorPoolKey: Hashable, CustomStringConvertible {
    public let developerDir: DeveloperDir
    public let testDestination: TestDestination
    public let testRunnerTool: TestRunnerTool
    public let simulatorControlTool: SimulatorControlTool
    
    public init(
        developerDir: DeveloperDir,
        testDestination: TestDestination,
        testRunnerTool: TestRunnerTool,
        simulatorControlTool: SimulatorControlTool
    ) {
        self.developerDir = developerDir
        self.testDestination = testDestination
        self.testRunnerTool = testRunnerTool
        self.simulatorControlTool = simulatorControlTool
    }
    
    public var description: String {
        return "<\(type(of: self)): destination: \(testDestination), testRunnerTool: \(testRunnerTool), simulatorControlTool: \(simulatorControlTool), developerDir: \(developerDir)>"
    }
}
