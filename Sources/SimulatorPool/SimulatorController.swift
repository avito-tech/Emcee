import Foundation
import SimulatorPoolModels

public protocol SimulatorController {
    func apply(simulatorOperationTimeouts: SimulatorOperationTimeouts)
    
    func createdSimulator() throws -> Simulator
    func bootedSimulator() throws -> Simulator
    func shutdownSimulator() throws
    func deleteSimulator() throws
    
    func simulatorBecameBusy()
    func simulatorBecameIdle()
}
