import CLTExtensions
import Dispatch
import Foundation

final class SettableOperation: Operation, CascadeCancellable {
    private let lock = NSLock()
    private var cascaseCancellableDependencies = [Operation]()
    private var isAbleToRun: Bool {
        willSet {
            willChangeValue(forKey: "isReady")
        }
        didSet {
            didChangeValue(forKey: "isReady")
        }
    }
    
    public static func finishedOperation() -> SettableOperation {
        return SettableOperation(isAbleToRun: true)
    }
    
    public static func pendingOperation() -> SettableOperation {
        return SettableOperation(isAbleToRun: false)
    }

    private init(isAbleToRun: Bool) {
        self.isAbleToRun = isAbleToRun
    }
    
    public override var isReady: Bool {
        return isAbleToRun && super.isReady
    }
    
    public func unblock() {
        lock.whileLocked { isAbleToRun = true }
    }
    
    func addCascadeCancellableDependency(_ operation: Operation) {
        cascaseCancellableDependencies.append(operation)
        operation.addDependency(self)
    }
    
    public override func cancel() {
        super.cancel()
        for dependency in cascaseCancellableDependencies {
            dependency.cancel()
        }
    }
}
