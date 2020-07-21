import Foundation
import QueueModels
import SocketModels

public protocol WorkerDetailsHolder {
    func update(workerId: WorkerId, restAddress: SocketAddress)
    
    var knownAddresses: [WorkerId: SocketAddress] { get }
}
