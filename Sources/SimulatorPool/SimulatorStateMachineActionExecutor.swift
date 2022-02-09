import Foundation
import PathLib
import SimulatorPoolModels

public protocol SimulatorStateMachineActionExecutor {
    func performCreateSimulatorAction(
        environment: [String: String],
        simDeviceType: SimDeviceType,
        simRuntime: SimRuntime,
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
