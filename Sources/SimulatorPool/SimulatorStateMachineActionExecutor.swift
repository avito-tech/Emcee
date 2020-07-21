import Foundation
import SimulatorPoolModels
import PathLib

public protocol SimulatorStateMachineActionExecutor {
    func performCreateSimulatorAction(
        environment: [String: String],
        testDestination: TestDestination,
        timeout: TimeInterval
    ) throws -> Simulator
    
    func performBootSimulatorAction(
        environment: [String: String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws
    
    func performShutdownSimulatorAction(
        environment: [String: String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws

    func performDeleteSimulatorAction(
        environment: [String: String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws
}
