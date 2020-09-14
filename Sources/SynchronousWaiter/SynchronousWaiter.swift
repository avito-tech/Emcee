import Darwin
import Foundation
import Logging

public final class SynchronousWaiter: Waiter {
    public init() {}
    
    public func waitWhile(
        pollPeriod: TimeInterval = 0.3,
        timeout: Timeout = .infinity,
        condition: WaitCondition
    ) throws {
        Logger.debug("Waiting for \(timeout.description), checking every \(pollPeriod) sec for up to \(timeout.value) sec")
        let startTime = Date().timeIntervalSince1970
        
        defer {
            Logger.debug("Finished waiting for \(timeout.description), took \(Date().timeIntervalSince1970 - startTime) sec")
        }
        
        while try condition() {
            let currentTime = Date().timeIntervalSince1970
            let executionDuration = currentTime - startTime
            if executionDuration > timeout.value {
                Logger.error("Operation '\(timeout.description)' timed out after running for more than \(LoggableDuration(timeout.value)) (\(LoggableDuration(executionDuration))")
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
