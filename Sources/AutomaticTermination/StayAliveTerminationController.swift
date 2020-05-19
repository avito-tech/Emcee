import Foundation

public final class StayAliveTerminationController: AutomaticTerminationController, CustomStringConvertible {
    public init() {}
    public func add(handler: () -> ()) {}
    public func startTracking() {}
    public func indicateActivityFinished() {}
    public let isTerminationAllowed = false
    
    public var description: String {
        return "<StayAlive>"
    }
}
