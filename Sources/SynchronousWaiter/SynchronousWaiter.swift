import Darwin
import Foundation

public final class SynchronousWaiter {
    
    public struct Timeout: CustomStringConvertible {
        public let description: String
        public let value: TimeInterval
        
        public init(description: String, value: TimeInterval) {
            self.description = description
            self.value = value
        }
        
        public static var infinity: Timeout {
            return Timeout(description: "Infinite wait will never timeout", value: .infinity)
        }
    }
    
    public enum TimeoutError: Error, CustomStringConvertible {
        case waitTimeout(Timeout)
        
        public var description: String {
            switch self {
            case .waitTimeout(let timeout):
                return "SynchronousWaiter reached timeout of \(timeout.value) s for '\(timeout.description)' operation"
            }
        }
    }
    
    public typealias WaitCondition = () throws -> Bool
    
    public init() {}
    
    public static func wait(pollPeriod: TimeInterval = 0.3, timeout: TimeInterval) {
        try? waitWhile(pollPeriod: pollPeriod, timeout: timeout) { true }
    }
    
    public func waitWhile(
        pollPeriod: TimeInterval = 0.3,
        timeout: TimeInterval = .infinity,
        description: String = "No description provided",
        condition: WaitCondition) throws
    {
        return try waitWhile(
            pollPeriod: pollPeriod,
            timeout: Timeout(description: description, value: timeout),
            condition: condition)
    }
    
    public static func waitWhile(
        pollPeriod: TimeInterval = 0.3,
        timeout: TimeInterval = .infinity,
        description: String = "No description provided",
        condition: WaitCondition) throws
    {
        return try waitWhile(
            pollPeriod: pollPeriod,
            timeout: Timeout(description: description, value: timeout),
            condition: condition)
    }
    
    public static func waitWhile(
        pollPeriod: TimeInterval = 0.3,
        timeout: Timeout = .infinity,
        condition: WaitCondition) throws
    {
        let waiter = SynchronousWaiter()
        try waiter.waitWhile(
            pollPeriod: pollPeriod,
            timeout: timeout,
            condition: condition)
    }
    
    public func waitWhile(
        pollPeriod: TimeInterval = 0.3,
        timeout: Timeout = .infinity,
        condition: WaitCondition) throws
    {
        return try withoutActuallyEscaping(condition) { condition in
            try waitWhile(
                pollPeriod: pollPeriod,
                timeout: timeout,
                conditions: [condition])
        }
    }
    
    public func waitWhile(
        pollPeriod: TimeInterval = 0.3,
        timeout: Timeout = .infinity,
        conditions: [WaitCondition]) throws
    {
        let startTime = Date().timeIntervalSince1970
        let conditionsCheck: () throws -> Bool = {
            try conditions.filter { try $0() }.isEmpty
        }
        while try conditionsCheck() {
            let currentTime = Date().timeIntervalSince1970
            if currentTime - startTime > timeout.value {
                throw TimeoutError.waitTimeout(timeout)
            }
            if !RunLoop.current.run(mode: RunLoop.Mode.default, before: Date().addingTimeInterval(pollPeriod)) {
                let passedPollPeriod = Date().timeIntervalSince1970 - currentTime
                if passedPollPeriod < pollPeriod {
                    Thread.sleep(forTimeInterval: pollPeriod - passedPollPeriod)
                }
            }
        }
    }
}
