import Foundation
import PathLib
import SimulatorPoolModels
import TestDestination

public protocol SimulatorStateMachineActionExecutor {
    func performCreateSimulatorAction(
        environment: [String: String],
        testDestination: AppleTestDestination,
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
