import AppleTools
import Foundation
import Models
import PathLib
import ProcessController
import ResourceLocationResolver
import SimulatorPool
import TemporaryStuff
import fbxctest

public final class SimulatorStateMachineActionExecutorProviderImpl: SimulatorStateMachineActionExecutorProvider {
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let simulatorSetPathDeterminer: SimulatorSetPathDeterminer

    public init(
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorSetPathDeterminer: SimulatorSetPathDeterminer
    ) {
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.simulatorSetPathDeterminer = simulatorSetPathDeterminer
    }
    
    public func simulatorStateMachineActionExecutor(
        simulatorControlTool: SimulatorControlTool,
        testRunnerTool: TestRunnerTool
    ) throws -> SimulatorStateMachineActionExecutor {
        let simulatorSetPath = try simulatorSetPathDeterminer.simulatorSetPathSuitableForTestRunnerTool(
            testRunnerTool: testRunnerTool
        )
        
        switch simulatorControlTool {
        case .fbsimctl(let fbsimctlLocation):
            return FbsimctlBasedSimulatorStateMachineActionExecutor(
                fbsimctl: resourceLocationResolver.resolvable(withRepresentable: fbsimctlLocation),
                processControllerProvider: processControllerProvider,
                simulatorsContainerPath: simulatorSetPath
            )
        case .simctl:
            return SimctlBasedSimulatorStateMachineActionExecutor(
                processControllerProvider: processControllerProvider,
                simulatorSetPath: simulatorSetPath
            )
        }
    }
}
