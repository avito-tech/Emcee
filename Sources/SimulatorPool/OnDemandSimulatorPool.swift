import Dispatch
import Foundation
import Logging
import Models
import TemporaryStuff
import ResourceLocationResolver

public class OnDemandSimulatorPool<T> where T: SimulatorController {
    
    public struct Key: Hashable, CustomStringConvertible {
        public let numberOfSimulators: UInt
        public let developerDir: DeveloperDir
        public let testDestination: TestDestination
        public let fbsimctl: FbsimctlLocation
        
        public init(
            numberOfSimulators: UInt,
            developerDir: DeveloperDir,
            testDestination: TestDestination,
            fbsimctl: FbsimctlLocation
        ) {
            self.numberOfSimulators = numberOfSimulators
            self.developerDir = developerDir
            self.testDestination = testDestination
            self.fbsimctl = fbsimctl
        }
        
        public var description: String {
            return "<\(type(of: self)): \(numberOfSimulators) simulators, destination: \(testDestination)>"
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(testDestination)
            hasher.combine(fbsimctl)
            hasher.combine(numberOfSimulators)
        }
        
        public static func == (left: OnDemandSimulatorPool<T>.Key, right: OnDemandSimulatorPool<T>.Key) -> Bool {
            return left.testDestination == right.testDestination
                && left.fbsimctl == right.fbsimctl
                && left.numberOfSimulators == right.numberOfSimulators
        }
    }
    
    private let tempFolder: TemporaryFolder
    private var pools = [Key: SimulatorPool<T>]()
    private let syncQueue = DispatchQueue(label: "ru.avito.OnDemandSimulatorPool")
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TemporaryFolder
    ) {
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
    }
    
    deinit {
        deleteSimulators()
    }
    
    public func pool(key: Key) throws -> SimulatorPool<T> {
        return try syncQueue.sync {
            if let existingPool = pools[key] {
                Logger.verboseDebug("Got SimulatorPool for key \(key)")
                return existingPool
            } else {
                let pool = try SimulatorPool<T>(
                    numberOfSimulators: key.numberOfSimulators,
                    testDestination: key.testDestination,
                    fbsimctl: resourceLocationResolver.resolvable(withRepresentable: key.fbsimctl),
                    developerDir: key.developerDir,
                    tempFolder: tempFolder
                )
                pools[key] = pool
                Logger.verboseDebug("Created SimulatorPool for key \(key)")
                return pool
            }
        }
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
