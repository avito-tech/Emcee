import AppleTools
import DateProvider
import Foundation
import Models
import PathLib
import ProcessController
import QueueModels
import ResourceLocationResolver
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import TemporaryStuff
import fbxctest

public final class SimulatorStateMachineActionExecutorProviderImpl: SimulatorStateMachineActionExecutorProvider {
    private let dateProvider: DateProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let simulatorSetPathDeterminer: SimulatorSetPathDeterminer
    private let version: Version

    public init(
        dateProvider: DateProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorSetPathDeterminer: SimulatorSetPathDeterminer,
        version: Version
    ) {
        self.dateProvider = dateProvider
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.simulatorSetPathDeterminer = simulatorSetPathDeterminer
        self.version = version
    }
    
    public func simulatorStateMachineActionExecutor(
        simulatorControlTool: SimulatorControlTool
    ) throws -> SimulatorStateMachineActionExecutor {
        let simulatorSetPath = try simulatorSetPathDeterminer.simulatorSetPathSuitableForTestRunnerTool(
            simulatorLocation: simulatorControlTool.location
        )
        
        let simulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor
        
        switch simulatorControlTool.tool {
        case .fbsimctl(let fbsimctlLocation):
            simulatorStateMachineActionExecutor = FbsimctlBasedSimulatorStateMachineActionExecutor(
                fbsimctl: resourceLocationResolver.resolvable(withRepresentable: fbsimctlLocation),
                processControllerProvider: processControllerProvider,
                simulatorsContainerPath: simulatorSetPath
            )
        case .simctl:
            simulatorStateMachineActionExecutor = SimctlBasedSimulatorStateMachineActionExecutor(
                processControllerProvider: processControllerProvider,
                simulatorSetPath: simulatorSetPath
            )
        }
        
        return MetricSupportingSimulatorStateMachineActionExecutor(
            dateProvider: dateProvider,
            delegate: simulatorStateMachineActionExecutor,
            version: version
        )
    }
}
