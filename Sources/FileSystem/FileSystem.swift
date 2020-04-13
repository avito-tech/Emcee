import Foundation
import PathLib

public protocol FileSystem {
    func contentEnumerator(forPath: AbsolutePath) -> FileSystemEnumerator
    func createDirectory(atPath: AbsolutePath, withIntermediateDirectories: Bool) throws
    func delete(fileAtPath: AbsolutePath) throws
    func properties(forFileAtPath: AbsolutePath) -> FilePropertiesContainer
    var commonlyUsedPathsProvider: CommonlyUsedPathsProvider { get }
}
