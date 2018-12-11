import Dispatch
import Foundation

public final class AtomicValue<T> {
    private var value: T
    private let lock = NSLock()

    public init(_ value: T) {
        self.value = value
    }
    
    public func withExclusiveAccess(work: (inout T) throws -> ()) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        try work(&value)
        return value
    }
    
    public func currentValue() -> T {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
