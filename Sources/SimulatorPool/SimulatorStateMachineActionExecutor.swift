import Foundation
import Models
import PathLib

public protocol SimulatorStateMachineActionExecutor {
    func performCreateSimulatorAction(
        environment: [String: String],
        simulatorSetPath: AbsolutePath,
        testDestination: TestDestination,
        timeout: TimeInterval
    ) throws
    
    func performBootSimulatorAction(
        environment: [String: String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws
    
    func performShutdownSimulatorAction(
        environment: [String: String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws

    func performDeleteSimulatorAction(
        environment: [String: String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws
}
