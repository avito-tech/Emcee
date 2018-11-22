import Foundation

public extension Scanner {
    func scanToEnd() -> String? {
        if !isAtEnd {
            return String(string[string.index(string.startIndex, offsetBy: scanLocation)...])
        } else {
            return nil
        }
    }
}
