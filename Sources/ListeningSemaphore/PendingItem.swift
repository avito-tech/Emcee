import Foundation

final class PendingItem<T: ListeningSemaphoreAmounts> {
    public let resources: T
    public let operation: SettableOperation

    public init(resources: T, operation: SettableOperation) {
        self.resources = resources
        self.operation = operation
    }
}
