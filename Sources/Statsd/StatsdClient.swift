import Foundation
import Network

public protocol StatsdClient: class {
    var stateUpdateHandler: ((NWConnection.State) -> Void)? { get set }
    var state: NWConnection.State { get }
    
    func start(queue: DispatchQueue)
    func cancel()
    
    func send(content: Data)
}
