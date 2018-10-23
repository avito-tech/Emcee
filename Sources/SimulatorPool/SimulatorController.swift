import Foundation
import Models

public protocol SimulatorController: Hashable {
    func bootedSimulator() throws -> Simulator
    func deleteSimulator() throws
    
    init(simulator: Simulator, fbsimctl: ResolvableResourceLocation)
}
