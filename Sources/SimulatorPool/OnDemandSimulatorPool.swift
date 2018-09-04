import Dispatch
import Foundation
import Logging
import Models

public final class OnDemandSimulatorPool<T> where T: SimulatorController {
    
    public struct Key: Hashable, CustomStringConvertible {
        public let numberOfSimulators: UInt
        public let testDestination: TestDestination
        public let auxiliaryPaths: AuxiliaryPaths
        
        public init(numberOfSimulators: UInt, testDestination: TestDestination, auxiliaryPaths: AuxiliaryPaths) {
            self.numberOfSimulators = numberOfSimulators
            self.testDestination = testDestination
            self.auxiliaryPaths = auxiliaryPaths
        }
        
        public var description: String {
            return "<\(type(of: self)): \(numberOfSimulators) simulators, destination: \(testDestination)>"
        }
    }
    
    private var pools = [Key: SimulatorPool<T>]()
    private let syncQueue = DispatchQueue(label: "ru.avito.OnDemandSimulatorPool")
    
    public init() {}
    
    deinit {
        deleteSimulators()
    }
    
    public func pool(key: Key) -> SimulatorPool<T> {
        var pool: SimulatorPool<T>?
        syncQueue.sync {
            if let existingPool = pools[key] {
                log("Got SimulatorPool for key \(key)")
                pool = existingPool
            } else {
                pool = SimulatorPool(
                    numberOfSimulators: key.numberOfSimulators,
                    testDestination: key.testDestination,
                    auxiliaryPaths: key.auxiliaryPaths)
                pools[key] = pool
                log("Created SimulatorPool for key \(key)")
            }
        }
        return pool!
    }
    
    public func deleteSimulators() {
        syncQueue.sync {
            for pool in pools.values {
                pool.deleteSimulators()
            }
            pools.removeAll()
        }
    }
}
