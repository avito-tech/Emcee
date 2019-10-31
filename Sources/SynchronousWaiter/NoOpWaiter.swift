import Foundation

public final class NoOpWaiter: Waiter {
    public init() {}
    
    public func waitWhile(pollPeriod: TimeInterval, timeout: Timeout, condition: () throws -> Bool) throws {}
}
