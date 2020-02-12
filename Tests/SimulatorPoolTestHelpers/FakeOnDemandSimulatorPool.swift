import Foundation
import SimulatorPool

public final class FakeOnDemandSimulatorPool: OnDemandSimulatorPool {
    public var pools = [OnDemandSimulatorPoolKey: SimulatorPoolMock]()
    
    public init() {}
    
    public func pool(key: OnDemandSimulatorPoolKey) throws -> SimulatorPool {
        if let existingPool = pools[key] {
            return existingPool
        } else {
            let pool = SimulatorPoolMock()
            pools[key] = pool
            return pool
        }
    }
    
    public func enumeratePools(iterator: (OnDemandSimulatorPoolKey, SimulatorPool) -> ()) {
        for (k, v) in pools {
            iterator(k, v)
        }
    }
}
