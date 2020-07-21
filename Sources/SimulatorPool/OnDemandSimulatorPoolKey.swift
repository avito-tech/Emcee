import DeveloperDirModels
import Foundation
import SimulatorPoolModels

public struct OnDemandSimulatorPoolKey: Hashable, CustomStringConvertible {
    public let developerDir: DeveloperDir
    public let testDestination: TestDestination
    public let simulatorControlTool: SimulatorControlTool
    
    public init(
        developerDir: DeveloperDir,
        testDestination: TestDestination,
        simulatorControlTool: SimulatorControlTool
    ) {
        self.developerDir = developerDir
        self.testDestination = testDestination
        self.simulatorControlTool = simulatorControlTool
    }
    
    public var description: String {
        return "<\(type(of: self)): destination: \(testDestination), simulatorControlTool: \(simulatorControlTool), developerDir: \(developerDir)>"
    }
}
