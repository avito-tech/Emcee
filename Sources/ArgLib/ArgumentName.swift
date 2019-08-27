import Foundation

public enum ArgumentName: CustomStringConvertible, Hashable {
    /// Represents a double dashed arg. For dashless name "arg" the input argument is "--arg".
    case doubleDashed(dashlessName: String)
    
    public var description: String {
        return expectedInputValue
    }
    
    var expectedInputValue: String {
        switch self {
        case .doubleDashed(let dashlessName):
            return "--\(dashlessName)"
        }
    }
}
