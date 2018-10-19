import Dispatch
import Foundation
import Logging
import Models
import TempFolder

public final class OnDemandSimulatorPool<T> where T: SimulatorController {
    
    public struct Key: Hashable, CustomStringConvertible {
        public let numberOfSimulators: UInt
        public let testDestination: TestDestination
        public let auxiliaryPaths: AuxiliaryPaths
        public let tempFolder: TempFolder
        
        public init(numberOfSimulators: UInt, testDestination: TestDestination, auxiliaryPaths: AuxiliaryPaths, tempFolder: TempFolder) {
            self.numberOfSimulators = numberOfSimulators
            self.testDestination = testDestination
            self.auxiliaryPaths = auxiliaryPaths
            self.tempFolder = tempFolder
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
    
    public func pool(key: Key) throws -> SimulatorPool<T> {
        var pool: SimulatorPool<T>?
        try syncQueue.sync {
            if let existingPool = pools[key] {
                log("Got SimulatorPool for key \(key)")
                pool = existingPool
            } else {
                pool = try SimulatorPool(
                    numberOfSimulators: key.numberOfSimulators,
                    testDestination: key.testDestination,
                    auxiliaryPaths: key.auxiliaryPaths,
                    tempFolder: key.tempFolder)
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
