import AppleTools
import DeveloperDirLocator
import Foundation
import Models
import ResourceLocationResolver
import SimulatorPool
import fbxctest

public final class DefaultSimulatorControllerProvider: SimulatorControllerProvider {
    
    private let maximumBootAttempts: UInt
    private let resourceLocationResolver: ResourceLocationResolver
    private let simulatorBootQueue: DispatchQueue
    
    public init(
        maximumBootAttempts: UInt,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorBootQueue: DispatchQueue
    ) {
        self.maximumBootAttempts = maximumBootAttempts
        self.resourceLocationResolver = resourceLocationResolver
        self.simulatorBootQueue = simulatorBootQueue
    }

    public func createSimulatorController(
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        simulator: Simulator,
        simulatorControlTool: SimulatorControlTool
    ) throws -> SimulatorController {
        let simulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor
        switch simulatorControlTool {
        case .fbsimctl(let fbsimctlLocation):
            simulatorStateMachineActionExecutor = FbsimctlBasedSimulatorStateMachineActionExecutor(
                fbsimctl: resourceLocationResolver.resolvable(withRepresentable: fbsimctlLocation)
            )
        case .simctl:
            simulatorStateMachineActionExecutor = SimctlBasedSimulatorStateMachineActionExecutor()
        }
        
        return StateMachineDrivenSimulatorController(
            bootQueue: simulatorBootQueue,
            developerDir: developerDir,
            developerDirLocator: developerDirLocator,
            maximumBootAttempts: maximumBootAttempts,
            simulator: simulator,
            simulatorOperationTimeouts: StateMachineDrivenSimulatorController.SimulatorOperationTimeouts(create: 30, boot: 180, delete: 20, shutdown: 20),
            simulatorStateMachine: SimulatorStateMachine(),
            simulatorStateMachineActionExecutor: simulatorStateMachineActionExecutor
        )
    }
}
