import Foundation
import SimulatorPoolModels

public protocol CoreSimulatorStateProvider {
    func coreSimulatorState(simulator: Simulator) throws -> CoreSimulatorState?
}
