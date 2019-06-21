import Foundation
import FileHasher

public final class FileHashVersionProvider: VersionProvider {
    private let hasher: FileHasher
    
    public init(url: URL) {
        hasher = FileHasher(fileUrl: url)
    }
    
    public func version() throws -> Version {
        return Version(value: try hasher.hash())
    }
}
