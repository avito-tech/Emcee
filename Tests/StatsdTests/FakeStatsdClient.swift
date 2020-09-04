import Foundation
import Network
import Statsd

final class FakeStatsdClient: StatsdClient {
    var state: NWConnection.State
    
    var sentData: [Data] = []
    var stateUpdateHandler: ((NWConnection.State) -> Void)?
    
    init(initialState: NWConnection.State) {
        state = initialState
    }
    
    func cancel() {}
    func start(queue: DispatchQueue) {}
    
    func send(content: Data) {
        sentData.append(content)
    }
    
    func update(state: NWConnection.State) {
        self.state = state
        self.stateUpdateHandler?(state)
    }
}
