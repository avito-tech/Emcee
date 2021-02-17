import AppleTools
import DateProvider
import Foundation
import Metrics
import MetricsExtensions
import PathLib
import ProcessController
import QueueModels
import ResourceLocationResolver
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import Tmp
import fbxctest

public final class SimulatorStateMachineActionExecutorProviderImpl: SimulatorStateMachineActionExecutorProvider {
    private let dateProvider: DateProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let simulatorSetPathDeterminer: SimulatorSetPathDeterminer
    private let version: Version
    private let globalMetricRecorder: GlobalMetricRecorder

    public init(
        dateProvider: DateProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorSetPathDeterminer: SimulatorSetPathDeterminer,
        version: Version,
        globalMetricRecorder: GlobalMetricRecorder
    ) {
        self.dateProvider = dateProvider
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.simulatorSetPathDeterminer = simulatorSetPathDeterminer
        self.version = version
        self.globalMetricRecorder = globalMetricRecorder
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
            version: version,
            globalMetricRecorder: globalMetricRecorder
        )
    }
}
