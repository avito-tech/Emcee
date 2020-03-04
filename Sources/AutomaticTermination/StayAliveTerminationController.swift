import Foundation

public final class StayAliveTerminationController: AutomaticTerminationController {
    public init() {}
    public func add(handler: () -> ()) {}
    public func startTracking() {}
    public func indicateActivityFinished() {}
    public let isTerminationAllowed = false
}
