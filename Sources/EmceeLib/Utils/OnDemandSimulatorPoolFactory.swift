import DeveloperDirLocator
import Foundation
import ProcessController
import ResourceLocationResolver
import SimulatorPool
import TemporaryStuff
import UniqueIdentifierGenerator

public final class OnDemandSimulatorPoolFactory {
    public static func create(
        developerDirLocator: DeveloperDirLocator,
        additionalBootAttempts: UInt = 2,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorBootQueue: DispatchQueue = DispatchQueue(label: "SimulatorBootQueue"),
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) -> OnDemandSimulatorPool {
        return OnDemandSimulatorPool(
            developerDirLocator: developerDirLocator,
            resourceLocationResolver: resourceLocationResolver,
            simulatorControllerProvider: DefaultSimulatorControllerProvider(
                additionalBootAttempts: additionalBootAttempts,
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
