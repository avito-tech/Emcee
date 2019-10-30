import DeveloperDirLocator
import Foundation
import ResourceLocationResolver
import SimulatorPool
import TemporaryStuff

public final class OnDemandSimulatorPoolFactory {
    public static func create(
        developerDirLocator: DeveloperDirLocator,
        maximumBootAttempts: UInt = 2,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorBootQueue: DispatchQueue = DispatchQueue(label: "SimulatorBootQueue"),
        tempFolder: TemporaryFolder
    ) -> OnDemandSimulatorPool {
        return OnDemandSimulatorPool(
            developerDirLocator: developerDirLocator,
            resourceLocationResolver: resourceLocationResolver,
            simulatorControllerProvider: DefaultSimulatorControllerProvider(
                maximumBootAttempts: maximumBootAttempts,
                resourceLocationResolver: resourceLocationResolver,
                simulatorBootQueue: simulatorBootQueue
            ),
            tempFolder: tempFolder
        )
    }
}
