import Foundation
import Models
import SimulatorPool

public final class FakeSimulatorController: SimulatorController {
    
    public let simulator: Simulator
    public let simulatorControlTool: SimulatorControlTool
    public let developerDir: DeveloperDir
    public var didCallDelete = false
    public var didCallShutdown = false
    
    public init(simulator: Simulator, simulatorControlTool: SimulatorControlTool, developerDir: DeveloperDir) {
        self.simulator = simulator
        self.simulatorControlTool = simulatorControlTool
        self.developerDir = developerDir
    }
    
    public func bootedSimulator() throws -> Simulator {
        return simulator
    }
    
    public func deleteSimulator() throws {
        didCallDelete = true
    }
    
    public func shutdownSimulator() throws {
        didCallShutdown = true
    }
}
