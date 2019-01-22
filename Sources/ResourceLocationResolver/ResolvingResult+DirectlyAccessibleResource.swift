import Foundation
import Models

public extension ResolvingResult {
    public enum DirectlyAccessibleResourceError: Error, CustomStringConvertible {
        case archiveFilenameNotSpecified(ResolvingResult)
        
        public var description: String {
            switch self {
            case .archiveFilenameNotSpecified(let resolvingResult):
                return "Unable to resolve directly accessible resource for \(resolvingResult) because archive file name is not specified"
            }
        }
    }
    
    /// Returns path in case if ResolvingResult points to local file or to remote archive with specified file inside it.
    /// Otherwise throws error.
    public func directlyAccessibleResourcePath() throws -> String {
        switch self {
        case .directlyAccessibleFile(let path):
            return path
        case .contentsOfArchive(let containerPath, let filenameInArchive):
            if let filenameInArchive = filenameInArchive {
                return containerPath.appending(pathComponent: filenameInArchive)
            } else {
                throw DirectlyAccessibleResourceError.archiveFilenameNotSpecified(self)
            }
        }
    }
}
