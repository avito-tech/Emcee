import Foundation

public class ArgumentDescription: Hashable {
    public let name: String
    public let overview: String
    
    public init(name: String, overview: String) {
        self.name = name
        self.overview = overview
    }
    
    public static func == (left: ArgumentDescription, right: ArgumentDescription) -> Bool {
        return left.name == right.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
