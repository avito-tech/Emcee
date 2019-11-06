import AppleTools
import DeveloperDirLocator
import Foundation
import Models
import PathLib
import ResourceLocationResolver
import SimulatorPool
import TemporaryStuff
import fbxctest

public final class DefaultSimulatorControllerProvider: SimulatorControllerProvider {
    
    private let additionalBootAttempts: UInt
    private let resourceLocationResolver: ResourceLocationResolver
    private let simulatorBootQueue: DispatchQueue
    private let temporaryFolder: TemporaryFolder
    
    public init(
        additionalBootAttempts: UInt,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorBootQueue: DispatchQueue,
        temporaryFolder: TemporaryFolder
    ) {
        self.additionalBootAttempts = additionalBootAttempts
        self.resourceLocationResolver = resourceLocationResolver
        self.simulatorBootQueue = simulatorBootQueue
        self.temporaryFolder = temporaryFolder
    }

    public func createSimulatorController(
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        simulatorControlTool: SimulatorControlTool,
        testDestination: TestDestination
    ) throws -> SimulatorController {
        let simulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor
        switch simulatorControlTool {
        case .fbsimctl(let fbsimctlLocation):
            simulatorStateMachineActionExecutor = FbsimctlBasedSimulatorStateMachineActionExecutor(
                fbsimctl: resourceLocationResolver.resolvable(withRepresentable: fbsimctlLocation),
                simulatorsContainerPath: try temporaryFolder.pathByCreatingDirectories(
                    components: ["fbsimctl_simulators", UUID().uuidString]
                )
            )
        case .simctl:
            simulatorStateMachineActionExecutor = SimctlBasedSimulatorStateMachineActionExecutor(
                simulatorSetPath: AbsolutePath.home.appending(relativePath: RelativePath("Library/Developer/CoreSimulator/Devices"))
            )
        }
        
        return StateMachineDrivenSimulatorController(
            additionalBootAttempts: additionalBootAttempts,
            bootQueue: simulatorBootQueue,
            developerDir: developerDir,
            developerDirLocator: developerDirLocator,
            simulatorOperationTimeouts: SimulatorOperationTimeouts(
                create: 30,
                boot: 180,
                delete: 20,
                shutdown: 20
            ),
            simulatorStateMachine: SimulatorStateMachine(),
            simulatorStateMachineActionExecutor: simulatorStateMachineActionExecutor,
            testDestination: testDestination
        )
    }
}
