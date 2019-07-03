import Foundation

public final class ToolchainConfiguration: Codable, Hashable {
    public let developerDir: DeveloperDir

    public init(developerDir: DeveloperDir) {
        self.developerDir = developerDir
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(developerDir)
    }
    
    public static func == (left: ToolchainConfiguration, right: ToolchainConfiguration) -> Bool {
        return left.developerDir == right.developerDir
    }
}
