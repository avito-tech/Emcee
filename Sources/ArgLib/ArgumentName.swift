import Foundation

public enum ArgumentName: Hashable {
    /// Represents a double dashed arg. For dashless name "arg" the input argument is "--arg".
    case doubleDashed(dashlessName: String)
    
    var expectedInputValue: String {
        switch self {
        case .doubleDashed(let dashlessName):
            return "--\(dashlessName)"
        }
    }
}
