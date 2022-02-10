import Foundation

public struct TestLogEntry: Codable, CustomStringConvertible, Hashable {
    public let contents: String
    
    public init(contents: String) {
        self.contents = contents
    }
    
    public var description: String {
        contents
    }
}
