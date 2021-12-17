import EmceeDI
import EmceeLogging
import Foundation
import QueueModels
import SimulatorPool
import Tmp

public final class OnDemandSimulatorPoolFactory {
    public static func create(
        di: DI,
        logger: ContextualLogger,
        simulatorBootQueue: DispatchQueue = DispatchQueue(label: "SimulatorBootQueue"),
        tempFolder: TemporaryFolder,
        version: Version
    ) throws -> OnDemandSimulatorPool {
        DefaultOnDemandSimulatorPool(
            logger: logger,
            simulatorControllerProvider: DefaultSimulatorControllerProvider(
                additionalBootAttempts: 2,
                developerDirLocator: try di.get(),
                fileSystem: try di.get(),
                logger: logger,
                simulatorBootQueue: simulatorBootQueue,
                simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProviderImpl(
                    dateProvider: try di.get(),
                    processControllerProvider: try di.get(),
                    simulatorSetPathDeterminer: SimulatorSetPathDeterminerImpl(
                        fileSystem: try di.get()
                    ),
                    version: version,
                    globalMetricRecorder: try di.get()
                )
            ),
            tempFolder: tempFolder
        )
    }
}
