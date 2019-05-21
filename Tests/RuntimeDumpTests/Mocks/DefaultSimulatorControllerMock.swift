@testable import SimulatorPool
import Foundation
import Models

final class DefaultSimulatorControllerMock: DefaultSimulatorController {

    let simulator: Simulator
    let fbsimctl: ResolvableResourceLocation

    var didCallDelete = false

    required init(simulator: Simulator, fbsimctl: ResolvableResourceLocation) {
        self.simulator = simulator
        self.fbsimctl = fbsimctl

        super.init(simulator: simulator, fbsimctl: fbsimctl)
    }

    override func bootedSimulator() throws -> Simulator {
        return simulator
    }

    override func deleteSimulator() throws {
        didCallDelete = true
    }

    static func == (l: DefaultSimulatorControllerMock, r: DefaultSimulatorControllerMock) -> Bool {
        return l.simulator == r.simulator
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(simulator)
    }
}
