import Foundation
import Models

public protocol WorkerDetailsHolder {
    func update(workerId: WorkerId, restAddress: SocketAddress)
    
    var knownAddresses: [WorkerId: SocketAddress] { get }
}
