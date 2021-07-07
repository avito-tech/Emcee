import AppleTools
import DateProvider
import Foundation
import Metrics
import MetricsExtensions
import PathLib
import ProcessController
import QueueModels
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import Tmp

public final class SimulatorStateMachineActionExecutorProviderImpl: SimulatorStateMachineActionExecutorProvider {
    private let dateProvider: DateProvider
    private let processControllerProvider: ProcessControllerProvider
    private let simulatorSetPathDeterminer: SimulatorSetPathDeterminer
    private let version: Version
    private let globalMetricRecorder: GlobalMetricRecorder

    public init(
        dateProvider: DateProvider,
        processControllerProvider: ProcessControllerProvider,
        simulatorSetPathDeterminer: SimulatorSetPathDeterminer,
        version: Version,
        globalMetricRecorder: GlobalMetricRecorder
    ) {
        self.dateProvider = dateProvider
        self.processControllerProvider = processControllerProvider
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
