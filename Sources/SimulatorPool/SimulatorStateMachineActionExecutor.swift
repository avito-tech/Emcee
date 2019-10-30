import Foundation
import Models
import PathLib

public protocol SimulatorStateMachineActionExecutor {
    func performCreateSimulatorAction(
        environment: [String: String],
        testDestination: TestDestination,
        timeout: TimeInterval
    ) throws -> Simulator
    
    func performBootSimulatorAction(
        environment: [String: String],
        path: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws
    
    func performShutdownSimulatorAction(
        environment: [String: String],
        path: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws

    func performDeleteSimulatorAction(
        environment: [String: String],
        path: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws
}
