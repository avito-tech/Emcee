import DeveloperDirLocator
import Foundation
import ResourceLocationResolver
import SimulatorPool
import TemporaryStuff

public final class OnDemandSimulatorPoolFactory {
    public static func create(
        developerDirLocator: DeveloperDirLocator,
        additionalBootAttempts: UInt = 2,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorBootQueue: DispatchQueue = DispatchQueue(label: "SimulatorBootQueue"),
        tempFolder: TemporaryFolder
    ) -> OnDemandSimulatorPool {
        return OnDemandSimulatorPool(
            developerDirLocator: developerDirLocator,
            resourceLocationResolver: resourceLocationResolver,
            simulatorControllerProvider: DefaultSimulatorControllerProvider(
                additionalBootAttempts: additionalBootAttempts,
                resourceLocationResolver: resourceLocationResolver,
                simulatorBootQueue: simulatorBootQueue,
                temporaryFolder: tempFolder
            ),
            tempFolder: tempFolder
        )
    }
}
