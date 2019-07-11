@testable import SimulatorPool
import Foundation
import Models

final class DefaultSimulatorControllerMock: DefaultSimulatorController {

    let simulator: Simulator
    let fbsimctl: ResolvableResourceLocation
    let developerDir: DeveloperDir

    var didCallDelete = false

    required init(
        simulator: Simulator,
        fbsimctl: ResolvableResourceLocation,
        developerDir: DeveloperDir
    ) {
        self.simulator = simulator
        self.fbsimctl = fbsimctl
        self.developerDir = developerDir

        super.init(
            simulator: simulator,
            fbsimctl: fbsimctl,
            developerDir: developerDir
        )
    }

    override func bootedSimulator() throws -> Simulator {
        return simulator
    }

    override func deleteSimulator() throws {
        didCallDelete = true
    }
}
