import Foundation
import Models
import SimulatorPool

final class FakeSimulatorController: SimulatorController {
    
    let simulator: Simulator
    let fbsimctlPath: String
    
    var didCallDelete = false
    
    init(simulator: Simulator, fbsimctlPath: String) {
        self.simulator = simulator
        self.fbsimctlPath = fbsimctlPath
    }
    
    func bootedSimulator() throws -> Simulator {
        return simulator
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
