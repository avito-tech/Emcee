import Foundation
import Models
import SimulatorPool

final class FakeSimulatorController: SimulatorController {
    
    let simulator: Simulator
    let fbsimctl: ResourceLocation
    
    var didCallDelete = false
    
    init(simulator: Simulator, fbsimctl: ResourceLocation) {
        self.simulator = simulator
        self.fbsimctl = fbsimctl
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
