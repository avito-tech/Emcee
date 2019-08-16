import AutomaticTermination

public class AutomaticTerminationControllerFixture: AutomaticTerminationController {
    public var isTerminationAllowed: Bool
    
    public init(isTerminationAllowed: Bool) {
        self.isTerminationAllowed = isTerminationAllowed
    }
    
    public var indicatedActivityFinished = false
    
    public func indicateActivityFinished() {
        indicatedActivityFinished = true
    }
    
    public func add(handler: @escaping AutomaticTerminationControllerHandler) {}
    
    public func startTracking() {}
}
