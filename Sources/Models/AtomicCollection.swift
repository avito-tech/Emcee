import Foundation

public class AtomicCollection<T: Collection>: AtomicValue<T> {
    private let conditionLock: ConditionLock
    
    override public init(_ value: T) {
        self.conditionLock = ConditionLock(condition: value.count)
        super.init(value)
    }
    
    override func didUpdateValue() {
        conditionLock.condition = value.count
    }
    
    /// Locks the invoking thread for up to given time interval until after the number of elements in collection
    /// becomes equal to the given count, and invokes a given closure.
    /// - Parameter count: The number of elements in underlying collection to match on.
    /// - Parameter before: The date by which the lock must be acquired or the attempt will time out.
    /// - Parameter work: A closure that will be executed once lock will be acquired and before it will be released.
    /// - Returns: true if the lock is acquired within the time limit, false otherwise.
    public func waitWhen(
        count: Int,
        before: Date = Date.distantFuture,
        doWork work: (Bool) -> () = { _ in })
        -> Bool
    {
        return conditionLock.lockAndUnlock(whenCondition: count, before: before, work: work)
    }
}
