import Foundation

public struct ErrorForTestingPurposes: Error, CustomStringConvertible {
    public let text: String

    public init(text: String) {
        self.text = text
    }
    
    public init() {
        self.text = "Error for testing purposes"
    }
    
    public var description: String {
        return "\(type(of: self)) \(text)"
    }
}
