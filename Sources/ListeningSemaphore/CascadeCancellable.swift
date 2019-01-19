import Foundation

public protocol CascadeCancellable {
    /// Adds a receiver to the dependency of the given operation.
    /// When received is cancelled, it will cancel the given operation as well.
    func addCascadeCancellableDependency(_ operation: Operation)
}
