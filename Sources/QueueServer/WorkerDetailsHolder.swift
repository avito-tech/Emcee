import Foundation
import Models
import QueueModels

public protocol WorkerDetailsHolder {
    func update(workerId: WorkerId, restAddress: SocketAddress)
    
    var knownAddresses: [WorkerId: SocketAddress] { get }
}
