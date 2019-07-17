import Foundation
import ResourceLocationResolver
import SimulatorPool
import TemporaryStuff

public final class OnDemandSimulatorPoolFactory {
    public static func create(
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TemporaryFolder
    ) -> OnDemandSimulatorPool {
        return OnDemandSimulatorPool(
            resourceLocationResolver: resourceLocationResolver,
            simulatorControllerProvider: DefaultSimulatorControllerProvider(
                resourceLocationResolver: resourceLocationResolver
            ),
            tempFolder: tempFolder
        )
    }
}
