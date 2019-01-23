import Foundation

public typealias AutomaticTerminationControllerHandler = () -> ()

public protocol AutomaticTerminationController {
    
    /// Indicates if automatic termination is allowed.
    var isTerminationAllowed: Bool { get }
    
    /// Schedules triggering automatic termination handlers once automatic termination will be allowed.
    func startTracking()
    
    /// Adds a handler that will be triggered once automatic termination will be allowed.
    func add(handler: @escaping AutomaticTerminationControllerHandler)
    
    /// Allows to reset any internal timers that termination controller may have.
    func indicateActivityFinished()
}
