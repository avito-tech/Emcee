import DeveloperDirLocator
import Foundation
import ProcessController
import ResourceLocationResolver
import SimulatorPool
import SimulatorPoolModels
import TemporaryStuff
import UniqueIdentifierGenerator

public final class OnDemandSimulatorPoolFactory {
    public static func create(
        developerDirLocator: DeveloperDirLocator,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorBootQueue: DispatchQueue = DispatchQueue(label: "SimulatorBootQueue"),
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) -> OnDemandSimulatorPool {
        return DefaultOnDemandSimulatorPool(
            resourceLocationResolver: resourceLocationResolver,
            simulatorControllerProvider: DefaultSimulatorControllerProvider(
                additionalBootAttempts: 2,
                automaticSimulatorShutdown: 3600,
                developerDirLocator: developerDirLocator,
                simulatorBootQueue: simulatorBootQueue,
                simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProviderImpl(
                    processControllerProvider: processControllerProvider,
                    resourceLocationResolver: resourceLocationResolver,
                    simulatorSetPathDeterminer: SimulatorSetPathDeterminerImpl(
                        temporaryFolder: tempFolder,
                        uniqueIdentifierGenerator: uniqueIdentifierGenerator
                    )
                )
            ),
            tempFolder: tempFolder
        )
    }
}
