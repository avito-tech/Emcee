import Foundation
import PathLib

public enum ContentEnumerationStyle {
    case deep
    case shallow
}

public protocol FileSystem {
    func contentEnumerator(forPath: AbsolutePath, style: ContentEnumerationStyle) -> FileSystemEnumerator
    
    func createDirectory(atPath: AbsolutePath, withIntermediateDirectories: Bool) throws
    func createFile(atPath: AbsolutePath, data: Data?) throws
    
    func copy(source: AbsolutePath, destination: AbsolutePath) throws
    func move(source: AbsolutePath, destination: AbsolutePath) throws
    func delete(fileAtPath: AbsolutePath) throws
    
    func properties(forFileAtPath: AbsolutePath) -> FilePropertiesContainer
    var commonlyUsedPathsProvider: CommonlyUsedPathsProvider { get }
}
