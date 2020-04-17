import DeveloperDirLocator
import FileSystem
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
        fileSystem: FileSystem,
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
                developerDirLocator: developerDirLocator,
                simulatorBootQueue: simulatorBootQueue,
                simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProviderImpl(
                    processControllerProvider: processControllerProvider,
                    resourceLocationResolver: resourceLocationResolver,
                    simulatorSetPathDeterminer: SimulatorSetPathDeterminerImpl(
                        fileSystem: fileSystem,
                        temporaryFolder: tempFolder,
                        uniqueIdentifierGenerator: uniqueIdentifierGenerator
                    )
                )
            ),
            tempFolder: tempFolder
        )
    }
}
