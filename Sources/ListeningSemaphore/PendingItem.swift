import Foundation

final class PendingItem {
    public let resources: ResourceAmounts
    public let operation: SettableOperation

    public init(resources: ResourceAmounts, operation: SettableOperation) {
        self.resources = resources
        self.operation = operation
    }
}
