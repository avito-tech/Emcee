import Foundation

public protocol SimulatorController: Hashable {
    func bootedSimulator() throws -> Simulator
    func deleteSimulator() throws
    
    init(simulator: Simulator, fbsimctlPath: String)
}
