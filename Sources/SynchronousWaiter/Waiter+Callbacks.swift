import AtomicModels
import Foundation
import Logging

public struct WaiterHasDiedBeforeValueWasSet: Error, CustomStringConvertible {
    public let pollPeriod: TimeInterval
    public let timeout: TimeInterval
    public let waiterDescription: String

    public init(
        pollPeriod: TimeInterval,
        timeout: TimeInterval,
        waiterDescription: String
    ) {
        self.pollPeriod = pollPeriod
        self.timeout = timeout
        self.waiterDescription = waiterDescription
    }
    
    public var description: String {
        return "Waiter for '\(waiterDescription)' operation (checking every \(LoggableDuration(pollPeriod)) for up to \(LoggableDuration(timeout)) died before a value was provided"
    }
}

public final class CallbackWaiter<T> {
    private let value = AtomicValue<T?>(nil)
    private weak var waiter: Waiter?
    
    init(waiter: Waiter) {
        self.waiter = waiter
    }
    
    public func set(result: T) { value.set(result) }
    public func currentValue() -> T? { value.currentValue() }
    
    public func wait(
        pollPeriod: TimeInterval = 0.1,
        timeout: TimeInterval,
        description: String
    ) throws -> T {
        guard let waiter = waiter else {
            throw WaiterHasDiedBeforeValueWasSet(pollPeriod: pollPeriod, timeout: timeout, waiterDescription: description)
        }
        
        return try waiter.waitForUnwrap(
            pollPeriod: pollPeriod,
            timeout: timeout,
            valueProvider: { () -> T? in
                currentValue()
            },
            description: description
        )
    }
}

public extension Waiter {
    func createCallbackWaiter<T>() -> CallbackWaiter<T> {
        return CallbackWaiter<T>(waiter: self)
    }
}
