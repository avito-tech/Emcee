import Foundation
import ListeningSemaphore

final class ResourceAmounts: ListeningSemaphoreAmounts {
    public let runningTests: Int

    public init(runningTests: Int) {
        self.runningTests = runningTests
    }
    
    public var description: String {
        return "<\(type(of: self)) runningTests=\(runningTests)>"
    }
    
    public func cappedTo(_ maximumValues: ResourceAmounts) -> ResourceAmounts {
        return ResourceAmounts(
            runningTests: min(runningTests, maximumValues.runningTests)
        )
    }
    
    public static func of(runningTests: Int = 0) -> ResourceAmounts {
        return ResourceAmounts(runningTests: runningTests)
    }
    
    public static let zero = ResourceAmounts(runningTests: 0)
    
    public static func == (left: ResourceAmounts, right: ResourceAmounts) -> Bool {
        return left.runningTests == right.runningTests
    }
    
    public static func +(left: ResourceAmounts, right: ResourceAmounts) -> ResourceAmounts {
        return ResourceAmounts(
            runningTests: left.runningTests + right.runningTests
        )
    }
    
    public static func -(left: ResourceAmounts, right: ResourceAmounts) -> ResourceAmounts {
        return ResourceAmounts(
            runningTests: left.runningTests - right.runningTests
        )
    }
    
    public func containsAllValuesLessThanOrEqualTo(_ otherAmounts: ResourceAmounts) -> Bool {
        return runningTests <= otherAmounts.runningTests
    }
    
    public func containsAnyValueLessThan(_ otherAmounts: ResourceAmounts) -> Bool {
        return runningTests < otherAmounts.runningTests
    }
}
