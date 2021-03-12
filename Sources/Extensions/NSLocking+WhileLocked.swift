import Foundation

public extension NSLocking {
    func whileLocked<T>(_ work: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try work()
    }
}
