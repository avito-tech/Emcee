import Foundation

public final class ResourceAmounts: Equatable, CustomStringConvertible {
    public let bootingSimulators: Int
    public let runningTests: Int

    public init(bootingSimulators: Int, runningTests: Int) {
        self.bootingSimulators = bootingSimulators
        self.runningTests = runningTests
    }
    
    public var description: String {
        return "<\(type(of: self)) bootingSimulators=\(bootingSimulators) runningTests=\(runningTests)>"
    }
    
    public func cappedTo(_ maximumValues: ResourceAmounts) -> ResourceAmounts {
        return ResourceAmounts(
            bootingSimulators: min(bootingSimulators, maximumValues.bootingSimulators),
            runningTests: min(runningTests, maximumValues.runningTests))
    }
    
    public static func of(bootingSimulators: Int = 0, runningTests: Int = 0) -> ResourceAmounts {
        return ResourceAmounts(bootingSimulators: bootingSimulators, runningTests: runningTests)
    }
    
    public static let zero = ResourceAmounts(bootingSimulators: 0, runningTests: 0)
    
    public static func == (left: ResourceAmounts, right: ResourceAmounts) -> Bool {
        return left.bootingSimulators == right.bootingSimulators
            && left.runningTests == right.runningTests
    }
    
    public static func +(left: ResourceAmounts, right: ResourceAmounts) -> ResourceAmounts {
        return ResourceAmounts(
            bootingSimulators: left.bootingSimulators + right.bootingSimulators,
            runningTests: left.runningTests + right.runningTests)
    }
    
    public static func -(left: ResourceAmounts, right: ResourceAmounts) -> ResourceAmounts {
        return ResourceAmounts( 
            bootingSimulators: left.bootingSimulators - right.bootingSimulators,
            runningTests: left.runningTests - right.runningTests)
    }
    
    public static func <=(left: ResourceAmounts, right: ResourceAmounts) -> Bool {
        return left.bootingSimulators <= right.bootingSimulators
            && left.runningTests <= right.runningTests
    }
    
    public func containsValuesLessThan(_ otherAmounts: ResourceAmounts) -> Bool {
        return bootingSimulators < otherAmounts.bootingSimulators
            || runningTests < otherAmounts.runningTests
    }
}
