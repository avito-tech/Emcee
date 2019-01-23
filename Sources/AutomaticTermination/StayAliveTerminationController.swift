import Foundation

internal final class StayAliveTerminationController: AutomaticTerminationController {
    public init() {}
    func add(handler: () -> ()) {}
    func startTracking() {}
    func indicateActivityFinished() {}
    let isTerminationAllowed = false
}
