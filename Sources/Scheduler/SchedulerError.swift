import Foundation

public enum SchedulerError: Error, CustomStringConvertible {
    case someErrorsHappened([Error])
    
    public var description: String {
        switch self {
        case .someErrorsHappened(let errors):
            return "During execution of tests the following errors happened: \(errors)"
        }
    }
}
