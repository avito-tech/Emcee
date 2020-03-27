public enum ExecutionOrder: Equatable {
    case before
    case equal
    case after
}

public protocol DefinesExecutionOrder {
    func executionOrder(relativeTo other: Self) -> ExecutionOrder
}
