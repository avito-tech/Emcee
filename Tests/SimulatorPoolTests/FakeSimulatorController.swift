import Foundation
import Models
import SimulatorPool

final class FakeSimulatorController: SimulatorController {
    
    let simulator: Simulator
    let fbsimctl: ResolvableResourceLocation
    
    var didCallDelete = false
    var didCallShutdown = false
    
    init(simulator: Simulator, fbsimctl: ResolvableResourceLocation) {
        self.simulator = simulator
        self.fbsimctl = fbsimctl
    }
    
    func bootedSimulator() throws -> Simulator {
        return simulator
    }
    
    func shutdownSimulator() throws {
        didCallShutdown = true
    }
    
    func deleteSimulator() throws {
        didCallDelete = true
    }
    
    static func == (l: FakeSimulatorController, r: FakeSimulatorController) -> Bool {
        return l.simulator == r.simulator
    }
    
    public var hashValue: Int {
        return simulator.hashValue
    }
}
