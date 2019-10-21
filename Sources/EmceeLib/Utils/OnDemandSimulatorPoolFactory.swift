import DeveloperDirLocator
import Foundation
import ResourceLocationResolver
import SimulatorPool
import TemporaryStuff

public final class OnDemandSimulatorPoolFactory {
    public static func create(
        developerDirLocator: DeveloperDirLocator,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TemporaryFolder
    ) -> OnDemandSimulatorPool {
        return OnDemandSimulatorPool(
            developerDirLocator: developerDirLocator,
            resourceLocationResolver: resourceLocationResolver,
            simulatorControllerProvider: DefaultSimulatorControllerProvider(
                resourceLocationResolver: resourceLocationResolver
            ),
            tempFolder: tempFolder
        )
    }
}
