import Foundation
import SimulatorPoolModels

public protocol SimulatorController {
    func bootedSimulator() throws -> Simulator
    func shutdownSimulator() throws
    func deleteSimulator() throws
    
    func simulatorBecameBusy()
    func simulatorBecameIdle()
}
