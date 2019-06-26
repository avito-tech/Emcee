import Foundation

public final class RelativePath: Path, Codable, Hashable {
    public let components: [String]
    
    public static let current = RelativePath(components: [])

    /// Builds a relative paths from given components. If components is empty, relative path will be equal to the current directory (`./`).
    public init(components: [String]) {
        self.components = components
    }
    
    public var pathString: String {
        guard !components.isEmpty else {
            return "./"
        }
        
        return components.joined(separator: "/")
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        self.components = StringPathParsing.components(path: stringValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(pathString)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(components)
    }
    
    public static func == (left: RelativePath, right: RelativePath) -> Bool {
        return left.components == right.components
    }
}
