import AtomicModels
import Foundation
import Models
import QueueModels

public final class WorkerDetailsHolderImpl: WorkerDetailsHolder {
    private let storage = AtomicValue<[WorkerId: SocketAddress]>([:])

    public init() {}
    
    public func update(workerId: WorkerId, restAddress: SocketAddress) {
        storage.withExclusiveAccess {
            $0[workerId] = restAddress
        }
    }
    
    public var knownAddresses: [WorkerId: SocketAddress] {
        return storage.currentValue()
    }
}
