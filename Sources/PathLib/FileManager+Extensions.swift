import Foundation

public extension FileManager {
    func createDirectory(
        atPath path: AbsolutePath,
        withIntermediateDirectories: Bool = true
    ) throws {
        try createDirectory(
            atPath: path.pathString,
            withIntermediateDirectories: withIntermediateDirectories
        )
    }
    
    var currentAbsolutePath: AbsolutePath {
        return AbsolutePath(currentDirectoryPath)
    }
}
