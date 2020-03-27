import Foundation
import QueueModels

extension Priority: DefinesExecutionOrder {
    public func executionOrder(relativeTo other: Priority) -> ExecutionOrder {
        if self == other {
            return .equal
        }
        
        return self > other ? .before : .after
    }
}
