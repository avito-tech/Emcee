import AutomaticTermination

public class AutomaticTerminationControllerFixture: AutomaticTerminationController {
    public var isTerminationAllowed: Bool
    
    public init(isTerminationAllowed: Bool) {
        self.isTerminationAllowed = isTerminationAllowed
    }
    
    public func indicateActivityFinished() {}
    public func add(handler: @escaping AutomaticTerminationControllerHandler) {}
    public func startTracking() {}
}
