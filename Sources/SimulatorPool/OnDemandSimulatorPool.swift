import Foundation
import EmceeLogging

public protocol OnDemandSimulatorPool {
    func pool(key: OnDemandSimulatorPoolKey) throws -> SimulatorPool
    
    func enumeratePools(iterator: (OnDemandSimulatorPoolKey, SimulatorPool) -> ())
}

public extension OnDemandSimulatorPool {
    func deleteSimulators() {
        enumeratePools { (key: OnDemandSimulatorPoolKey, pool: SimulatorPool) in
            pool.deleteSimulators()
        }
    }
}
