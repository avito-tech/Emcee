import Dispatch
import Foundation
import Logging
import Models
import ResourceLocationResolver
import TemporaryStuff

public class DefaultOnDemandSimulatorPool: OnDemandSimulatorPool {
    private let resourceLocationResolver: ResourceLocationResolver
    private let simulatorControllerProvider: SimulatorControllerProvider
    private let syncQueue = DispatchQueue(label: "ru.avito.OnDemandSimulatorPool")
    private let tempFolder: TemporaryFolder
    private var pools = [OnDemandSimulatorPoolKey: SimulatorPool]()
    
    public init(
        resourceLocationResolver: ResourceLocationResolver,
        simulatorControllerProvider: SimulatorControllerProvider,
        tempFolder: TemporaryFolder
    ) {
        self.resourceLocationResolver = resourceLocationResolver
        self.simulatorControllerProvider = simulatorControllerProvider
        self.tempFolder = tempFolder
    }
    
    deinit {
        deleteSimulators()
    }
    
    public func pool(key: OnDemandSimulatorPoolKey) throws -> SimulatorPool {
        return try syncQueue.sync {
            if let existingPool = pools[key] {
                Logger.verboseDebug("Got SimulatorPool for key \(key)")
                return existingPool
            } else {
                let pool = try DefaultSimulatorPool(
                    developerDir: key.developerDir,
                    simulatorControlTool: key.simulatorControlTool,
                    simulatorControllerProvider: simulatorControllerProvider,
                    tempFolder: tempFolder,
                    testDestination: key.testDestination,
                    testRunnerTool: key.testRunnerTool
                )
                pools[key] = pool
                Logger.verboseDebug("Created SimulatorPool for key \(key)")
                return pool
            }
        }
    }
    
    public func enumeratePools(iterator: (OnDemandSimulatorPoolKey, SimulatorPool) -> ()) {
        syncQueue.sync {
            for (key, value) in pools {
                iterator(key, value)
            }
        }
    }
}
