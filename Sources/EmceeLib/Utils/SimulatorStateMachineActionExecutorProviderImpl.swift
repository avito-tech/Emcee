import AppleTools
import Foundation
import Models
import PathLib
import ResourceLocationResolver
import SimulatorPool
import TemporaryStuff
import fbxctest

public final class SimulatorStateMachineActionExecutorProviderImpl: SimulatorStateMachineActionExecutorProvider {
    private let resourceLocationResolver: ResourceLocationResolver
    private let simulatorSetPathDeterminer: SimulatorSetPathDeterminer

    public init(
        resourceLocationResolver: ResourceLocationResolver,
        simulatorSetPathDeterminer: SimulatorSetPathDeterminer
    ) {
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
                simulatorsContainerPath: simulatorSetPath
            )
        case .simctl:
            return SimctlBasedSimulatorStateMachineActionExecutor(
                simulatorSetPath: simulatorSetPath
            )
        }
    }
}
