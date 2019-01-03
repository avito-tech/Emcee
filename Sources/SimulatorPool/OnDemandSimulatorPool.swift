import Dispatch
import Foundation
import Logging
import Models
import TempFolder
import ResourceLocationResolver

public final class OnDemandSimulatorPool<T> where T: SimulatorController {
    
    public struct Key: Hashable, CustomStringConvertible {
        public let numberOfSimulators: UInt
        public let testDestination: TestDestination
        public let fbsimctl: FbsimctlLocation
        
        public init(numberOfSimulators: UInt, testDestination: TestDestination, fbsimctl: FbsimctlLocation) {
            self.numberOfSimulators = numberOfSimulators
            self.testDestination = testDestination
            self.fbsimctl = fbsimctl
        }
        
        public var description: String {
            return "<\(type(of: self)): \(numberOfSimulators) simulators, destination: \(testDestination)>"
        }
        
        public var hashValue: Int {
            return testDestination.hashValue ^ fbsimctl.hashValue ^ numberOfSimulators.hashValue
        }
        
        public static func == (left: OnDemandSimulatorPool<T>.Key, right: OnDemandSimulatorPool<T>.Key) -> Bool {
            return left.testDestination == right.testDestination
                && left.fbsimctl == right.fbsimctl
                && left.numberOfSimulators == right.numberOfSimulators
        }
    }
    
    private let tempFolder: TempFolder
    private var pools = [Key: SimulatorPool<T>]()
    private let syncQueue = DispatchQueue(label: "ru.avito.OnDemandSimulatorPool")
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(resourceLocationResolver: ResourceLocationResolver, tempFolder: TempFolder) {
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
    }
    
    deinit {
        deleteSimulators()
    }
    
    public func pool(key: Key) throws -> SimulatorPool<T> {
        var pool: SimulatorPool<T>?
        try syncQueue.sync {
            if let existingPool = pools[key] {
                Logger.verboseDebug("Got SimulatorPool for key \(key)")
                pool = existingPool
            } else {
                pool = try SimulatorPool(
                    numberOfSimulators: key.numberOfSimulators,
                    testDestination: key.testDestination,
                    fbsimctl: resourceLocationResolver.resolvable(withRepresentable: key.fbsimctl),
                    tempFolder: tempFolder)
                pools[key] = pool
                Logger.verboseDebug("Created SimulatorPool for key \(key)")
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
