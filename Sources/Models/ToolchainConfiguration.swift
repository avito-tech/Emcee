import Foundation

public final class ToolchainConfiguration: Codable, Hashable, CustomStringConvertible {
    public let developerDir: DeveloperDir

    public init(developerDir: DeveloperDir) {
        self.developerDir = developerDir
    }
    
    public var description: String {
        return "\(developerDir)"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(developerDir)
    }
    
    public static func == (left: ToolchainConfiguration, right: ToolchainConfiguration) -> Bool {
        return left.developerDir == right.developerDir
    }
}
