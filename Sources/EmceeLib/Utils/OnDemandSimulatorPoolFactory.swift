import DI
import DateProvider
import DeveloperDirLocator
import FileSystem
import Foundation
import Metrics
import ProcessController
import QueueModels
import ResourceLocationResolver
import SimulatorPool
import SimulatorPoolModels
import TemporaryStuff
import UniqueIdentifierGenerator

public final class OnDemandSimulatorPoolFactory {
    public static func create(
        di: DI,
        simulatorBootQueue: DispatchQueue = DispatchQueue(label: "SimulatorBootQueue"),
        version: Version,
        metricRecorder: MetricRecorder
    ) throws -> OnDemandSimulatorPool {
        DefaultOnDemandSimulatorPool(
            resourceLocationResolver: try di.get(),
            simulatorControllerProvider: DefaultSimulatorControllerProvider(
                additionalBootAttempts: 2,
                developerDirLocator: try di.get(),
                simulatorBootQueue: simulatorBootQueue,
                simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProviderImpl(
                    dateProvider: try di.get(),
                    processControllerProvider: try di.get(),
                    resourceLocationResolver: try di.get(),
                    simulatorSetPathDeterminer: SimulatorSetPathDeterminerImpl(
                        fileSystem: try di.get(),
                        temporaryFolder: try di.get(),
                        uniqueIdentifierGenerator: try di.get()
                    ),
                    version: version,
                    metricRecorder: metricRecorder
                )
            ),
            tempFolder: try di.get()
        )
    }
}
