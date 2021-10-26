import Foundation

public enum LostTestProcessingMode: Equatable {
    /// Each test which result has been lost will be represented as `TestRunResult` with corresponding test exception.
    case reportError
    
    /// If test result is lost, no `TestRunResult` will be created for such test.
    case reportLost
}
