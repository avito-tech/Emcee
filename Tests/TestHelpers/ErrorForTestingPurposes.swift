import Foundation

public struct ErrorForTestingPurposes: Error, CustomStringConvertible {
    public let text: String

    public init(text: String = "Error for testing purposes") {
        self.text = text
    }
    
    public var description: String {
        return "\(type(of: self)) \(text)"
    }
}
