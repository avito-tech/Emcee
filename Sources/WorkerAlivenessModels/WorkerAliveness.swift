import Foundation
import Models

public struct WorkerAliveness: Codable, Equatable, CustomStringConvertible {
    public let registered: Bool
    public let bucketIdsBeingProcessed: Set<BucketId>
    public let disabled: Bool
    public let silent: Bool

    public init(
        registered: Bool,
        bucketIdsBeingProcessed: Set<BucketId>,
        disabled: Bool,
        silent: Bool
    ) {
        self.registered = registered
        self.bucketIdsBeingProcessed = bucketIdsBeingProcessed
        self.disabled = disabled
        self.silent = silent
    }
    
    public var alive: Bool { !silent }
    public var enabled: Bool { !disabled }
    
    public var description: String {
        return "\(registered ? "registered" : "not registered"), \(silent ? "silent" : "alive"), \(disabled ? "disabled" : "enabled"), processing bucket ids: \(bucketIdsBeingProcessed.sorted())"
    }
}
