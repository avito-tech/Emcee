import Foundation
import Models
import SimulatorPool
import SimulatorPoolModels

public final class FakeSimulatorController: SimulatorController {
    
    public let developerDir: DeveloperDir
    public let simulator: Simulator
    public let simulatorControlTool: SimulatorControlTool
    public var didCallDelete = false
    public var didCallShutdown = false
    public var isBusy = false
    public var onShutdown: () -> () = {}
    public var onDelete: () -> () = {}
    public var simulatorOperationTimeouts: SimulatorOperationTimeouts?
    
    public init(simulator: Simulator, simulatorControlTool: SimulatorControlTool, developerDir: DeveloperDir) {
        self.simulator = simulator
        self.simulatorControlTool = simulatorControlTool
        self.developerDir = developerDir
    }
    
    public func apply(simulatorOperationTimeouts: SimulatorOperationTimeouts) {
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
    }
    
    public func bootedSimulator() throws -> Simulator {
        return simulator
    }
    
    public func deleteSimulator() throws {
        didCallDelete = true
        onDelete()
    }
    
    public func shutdownSimulator() throws {
        didCallShutdown = true
        onShutdown()
    }
    
    public func simulatorBecameBusy() {
        isBusy = true
    }
    
    public func simulatorBecameIdle() {
        isBusy = false
    }
}
