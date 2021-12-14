import Foundation

/**
 * A semaphore that uses Operation for acquisition of different resource types rather than blocking.
 */
public final class ListeningSemaphore<T: ListeningSemaphoreAmounts> {
    var usedValues = T.zero
    let maximumValues: T
    private var pending = [PendingItem<T>]()
    private let lock = NSRecursiveLock()
    private let executionQueue = OperationQueue()
    
    public init(maximumValues: T) {
        self.maximumValues = maximumValues
    }
    
    /// Returns the operation which will be ready to be executed by the moment when required resources will be acquired.
    /// If resource amounts that need to be acquired are higher than maximum amounts, they will be capped to them.
    /// Operation may be returned in already completed state. 
    ///
    /// You typically create your own operation and add the operation returned by this method as a dependency to
    /// your operation, and perform resource-critical code inside your operation.
    ///
    /// When you finish your job, you must release acquired resources by calling release() method below.
    public func acquire(_ resources: T) throws -> Operation & CascadeCancellable {
        return try synchronized {
            if resources == .zero {
                return SettableOperation.finishedOperation()
            }
            
            let cappedResources = resources.cappedTo(maximumValues)
            let operation: SettableOperation
            if try checkIfResourcesAvailable(cappedResources) {
                operation = SettableOperation.finishedOperation()
                increaseUsedResources(cappedResources)
            } else {
                operation = SettableOperation.pendingOperation()
                pending.append(PendingItem(resources: cappedResources, operation: operation))
            }
            executionQueue.addOperation(operation)
            return operation
        }
    }
    
    /// Releases previously acquired resources. The amount of resources should match one you used during
    /// resource acquisition.
    public func release(_ resources: T) throws {
        guard resources != .zero else { return }
        let cappedResources = resources.cappedTo(maximumValues)
        try decreaseUsedResources(cappedResources)
        try processPendingItems(try pendingItemsThatCanBeProcessed())
    }
    
    private func pendingItemsThatCanBeProcessed() throws -> [PendingItem<T>] {
        return try synchronized {
            var items = [PendingItem<T>]()
            
            try MutatingIterator.iterate(&pending) { item in
                if availableResources == .zero {
                    return .break
                }
                
                if try checkIfResourcesAvailable(item.resources) {
                    items.append(item)
                    increaseUsedResources(item.resources)
                    return .removeAndContinue
                } else {
                    return .break
                }
            }
            return items
        }
    }
    
    /// Returns all available resources at the moment of invocation.
    public var availableResources: T {
        return synchronized {
            return maximumValues - usedValues
        }
    }
    
    /// Returns a length of pending resource acquiring operations.
    var queueLength: Int {
        return synchronized {
            return pending.count
        }
    }
    
    private func checkIfResourcesAvailable(_ resources: T) throws -> Bool {
        return try synchronized {
            guard resources.containsAllValuesLessThanOrEqualTo(maximumValues) else {
                throw Error.amountsAreNotCappedToMaximumAmounts(resources, maximum: maximumValues)
            }
            return (usedValues + resources).containsAllValuesLessThanOrEqualTo(maximumValues)
        }
    }
    
    private func increaseUsedResources(_ resources: T) {
        return synchronized {
            usedValues = usedValues + resources
        }
    }
    
    private func decreaseUsedResources(_ resources: T) throws {
        return try synchronized {
            let updatedAmounts = usedValues - resources
            guard !updatedAmounts.containsAnyValueLessThan(.zero) else {
                throw Error.unableToDecreaseAmounts(by: resources, current: usedValues, maximum: maximumValues)
            }
            usedValues = updatedAmounts
        }
    }

    private func processPendingItems(_ items: [PendingItem<T>]) throws {
        var failedAmounts = T.zero
        
        for item in items {
            if item.operation.isCancelled {
                failedAmounts = failedAmounts + item.resources
            } else {
                item.operation.unblock()
            }
        }
        
        if failedAmounts != .zero {
            try release(failedAmounts)
        }
    }
    
    private func synchronized<T>(execute work: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try work()
    }
    
    public enum `Error`: Swift.Error, CustomStringConvertible {
        case amountsAreNotCappedToMaximumAmounts(T, maximum: T)
        case unableToDecreaseAmounts(by: T, current: T, maximum: T)
        
        public var description: String {
            switch self {
            case .amountsAreNotCappedToMaximumAmounts(let amounts, let maximum):
                return "Resource amounts \(amounts) must be capped to the maximum amounts (\(maximum))"
            case .unableToDecreaseAmounts(let by, let current, let maximum):
                return "Cannot increase available resources by \(by). Current: \(current), Maximum: \(maximum)"
            }
        }
    }
}
