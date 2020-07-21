import Foundation

public protocol Waiter: class {
    typealias WaitCondition = () throws -> Bool
    
    func waitWhile(
        pollPeriod: TimeInterval,
        timeout: Timeout,
        condition: WaitCondition
    ) throws
}

public extension Waiter {
    func wait(pollPeriod: TimeInterval = 0.3, timeout: TimeInterval, description: String) {
        try? waitWhile(pollPeriod: pollPeriod, timeout: timeout, description: description) { true }
    }
    
    func waitWhile(
        pollPeriod: TimeInterval = 0.5,
        timeout: TimeInterval = .infinity,
        description: String,
        condition: WaitCondition
    ) throws {
        return try waitWhile(
            pollPeriod: pollPeriod,
            timeout: Timeout(description: description, value: timeout),
            condition: condition
        )
    }
}

public struct NoUnwrappableValueProvidedError: Error, CustomStringConvertible {
    public let waiter: Waiter

    public init(waiter: Waiter) {
        self.waiter = waiter
    }
    
    public var description: String {
        return "No unwrappable value provided back to waiter \(waiter)"
    }
}

public extension Waiter {
    func waitForUnwrap<T>(
        pollPeriod: TimeInterval = 0.1,
        timeout: TimeInterval,
        valueProvider: () throws -> T?,
        description: String
    ) throws -> T {
        var result: T?
        
        try waitWhile(pollPeriod: pollPeriod, timeout: timeout, description: description, condition: { () -> Bool in
            result = try valueProvider()
            return result == nil
        })
        
        if let result = result {
            return result
        } else {
            throw NoUnwrappableValueProvidedError(waiter: self)
        }
    }
}
