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
    
    public static func wait(pollPeriod: TimeInterval = 0.3, timeout: TimeInterval) {
        try? waitWhile(pollPeriod: pollPeriod, timeout: timeout) { true }
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
        let startTime = Date().timeIntervalSince1970
        while try condition() {
            let currentTime = Date().timeIntervalSince1970
            if currentTime - startTime > timeout.value {
                throw TimeoutError.waitTimeout(timeout)
            }
            if !RunLoop.current.run(mode: .defaultRunLoopMode, before: Date().addingTimeInterval(pollPeriod)) {
                let passedPollPeriod = Date().timeIntervalSince1970 - currentTime
                if passedPollPeriod < pollPeriod {
                    Thread.sleep(forTimeInterval: pollPeriod - passedPollPeriod)
                }
            }
        }
    }
}
