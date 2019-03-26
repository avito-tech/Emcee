import Foundation

public extension Process {
    enum NewProcessGroupError: String, Error, CustomStringConvertible {
        case failedToChangeProcessGroupBehavour = "Not able to create subprocesses within same process group. This could lead to orphan processes."
        public var description: String {
            return rawValue
        }
    }
    
    /**
     * If true, a new progress group is created for the child making it continue running even if
     * the parent is killed or interrupted. Default value is true.
     *
     * This method uses private API and will throw an error if it won't be able to use the private API.
     */
    func setStartsNewProcessGroup(_ value: Bool) throws {
        if let concreteTaskClass = NSClassFromString("NSConcreteTask"), self.isKind(of: concreteTaskClass) {
            self.perform(Selector(("setStartsNewProcessGroup:")), with: value)
        } else {
            throw NewProcessGroupError.failedToChangeProcessGroupBehavour
        }
    }
}
