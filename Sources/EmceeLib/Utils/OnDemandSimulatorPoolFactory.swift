import DateProvider
import DeveloperDirLocator
import FileSystem
import Foundation
import ProcessController
import QueueModels
import ResourceLocationResolver
import SimulatorPool
import SimulatorPoolModels
import TemporaryStuff
import UniqueIdentifierGenerator

public final class OnDemandSimulatorPoolFactory {
    public static func create(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorBootQueue: DispatchQueue = DispatchQueue(label: "SimulatorBootQueue"),
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        version: Version
    ) -> OnDemandSimulatorPool {
        return DefaultOnDemandSimulatorPool(
            resourceLocationResolver: resourceLocationResolver,
            simulatorControllerProvider: DefaultSimulatorControllerProvider(
                additionalBootAttempts: 2,
                developerDirLocator: developerDirLocator,
                simulatorBootQueue: simulatorBootQueue,
                simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProviderImpl(
                    dateProvider: dateProvider,
                    processControllerProvider: processControllerProvider,
                    resourceLocationResolver: resourceLocationResolver,
                    simulatorSetPathDeterminer: SimulatorSetPathDeterminerImpl(
                        fileSystem: fileSystem,
                        temporaryFolder: tempFolder,
                        uniqueIdentifierGenerator: uniqueIdentifierGenerator
                    ),
                    version: version
                )
            ),
            tempFolder: tempFolder
        )
    }
}
