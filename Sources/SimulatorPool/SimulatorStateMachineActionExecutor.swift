import Foundation
import Models
import PathLib

public protocol SimulatorStateMachineActionExecutor {
    func performCreateSimulatorAction(
        environment: [String: String],
        simulatorSetPath: AbsolutePath,
        testDestination: TestDestination
    ) throws
    
    func performBootSimulatorAction(
        environment: [String: String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: String
    ) throws
    
    func performShutdownSimulatorAction(
        environment: [String: String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: String
    ) throws

    func performDeleteSimulatorAction(
        environment: [String: String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: String
    ) throws
}
