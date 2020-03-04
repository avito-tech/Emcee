import Foundation
import Models

public protocol WorkerDetailsHolder {
    func update(workerId: WorkerId, restPort: Int)
    
    var knownPorts: [WorkerId: Int] { get }
}
