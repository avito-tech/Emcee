import Foundation

public protocol Waiter {
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
