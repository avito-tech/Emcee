import Foundation

/**
 * A semaphore that uses Operation for acquisition of different resource types rather than blocking.
 */
public final class ListeningSemaphore {
    var usedValues = ResourceAmounts.zero
    let maximumValues: ResourceAmounts
    private var pending = [PendingItem]()
    private let lock = NSRecursiveLock()
    private let executionQueue = OperationQueue()
    
    public init(maximumValues: ResourceAmounts) {
        self.maximumValues = maximumValues
    }
    
    /**
     * Returns the operation which will be ready to be executed by the moment when required resources will be acquired.
     * If resource amounts that need to be acquired are higher than maximum amounts, they will be capped to them.
     * Operation may be returned already completed. You should subscribe add your dependency to the operation
     * and perform your resource requiring job once the operation will be completed and not cancelled.
     *
     * You typically create your own operation and add the operation returned by this method as a dependency to
     * your operation, and perform resource-critical code inside your operation.
     *
     * When you finish your job, you must release acquired resources by calling release() method below.
     */
    public func acquire(_ resources: ResourceAmounts) throws -> Operation & CascadeCancellable {
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
    
    /**
     * Releases previously acquired resources. The amount of resources should match one you used during
     * resource acquisition.
     */
    public func release(_ resources: ResourceAmounts) throws {
        guard resources != .zero else { return }
        let cappedResources = resources.cappedTo(maximumValues)
        try decreaseUsedResources(cappedResources)
        try processPendingItems(try pendingItemsThatCanBeProcessed())
    }
    
    private func pendingItemsThatCanBeProcessed() throws -> [PendingItem] {
        return try synchronized {
            var items = [PendingItem]()
            
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
    
    public var availableResources: ResourceAmounts {
        return synchronized {
            return maximumValues - usedValues
        }
    }
    
    var queueLength: Int {
        return synchronized {
            return pending.count
        }
    }
    
    private func checkIfResourcesAvailable(_ resources: ResourceAmounts) throws -> Bool {
        return try synchronized {
            guard resources <= maximumValues else {
                throw Error.amountsAreNotCappedToMaximumAmounts(resources, maximum: maximumValues)
            }
            return (usedValues + resources) <= maximumValues
        }
    }
    
    private func increaseUsedResources(_ resources: ResourceAmounts) {
        return synchronized {
            usedValues = usedValues + resources
        }
    }
    
    private func decreaseUsedResources(_ resources: ResourceAmounts) throws {
        return try synchronized {
            let updatedAmounts = usedValues - resources
            guard !updatedAmounts.containsValuesLessThan(.zero) else {
                throw Error.unableToDecreaseAmounts(by: resources, current: usedValues, maximum: maximumValues)
            }
            usedValues = updatedAmounts
        }
    }

    private func processPendingItems(_ items: [PendingItem]) throws {
        var failedAmounts = ResourceAmounts.zero
        
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
        case amountsAreNotCappedToMaximumAmounts(ResourceAmounts, maximum: ResourceAmounts)
        case unableToDecreaseAmounts(by: ResourceAmounts, current: ResourceAmounts, maximum: ResourceAmounts)
        
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
