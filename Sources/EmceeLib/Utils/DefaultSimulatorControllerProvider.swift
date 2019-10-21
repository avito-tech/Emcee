import AppleTools
import DeveloperDirLocator
import Foundation
import Models
import ResourceLocationResolver
import SimulatorPool
import fbxctest

public final class DefaultSimulatorControllerProvider: SimulatorControllerProvider {
    
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(resourceLocationResolver: ResourceLocationResolver) {
        self.resourceLocationResolver = resourceLocationResolver
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
            developerDir: developerDir,
            developerDirLocator: developerDirLocator,
            simulator: simulator,
            simulatorStateMachine: SimulatorStateMachine(),
            simulatorStateMachineActionExecutor: simulatorStateMachineActionExecutor
        )
    }
}
