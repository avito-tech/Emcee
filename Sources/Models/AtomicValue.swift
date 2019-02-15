import Dispatch
import Foundation

public class AtomicValue<T> {
    internal var value: T
    private let lock = NSLock()

    public init(_ value: T) {
        self.value = value
    }
    
    public func withExclusiveAccess(work: (inout T) throws -> ()) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        try work(&value)
        didUpdateValue()
        return value
    }
    
    public func currentValue() -> T {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
    
    public func set(_ newValue: T) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
        didUpdateValue()
    }
    
    internal func didUpdateValue() {}
}
