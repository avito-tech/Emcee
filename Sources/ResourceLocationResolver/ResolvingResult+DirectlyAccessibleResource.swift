import Foundation
import Models
import PathLib
import ResourceLocation

public extension ResolvingResult {
    enum DirectlyAccessibleResourceError: Error, CustomStringConvertible {
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
    func directlyAccessibleResourcePath() throws -> AbsolutePath {
        switch self {
        case .directlyAccessibleFile(let path):
            return path
        case .contentsOfArchive(let containerPath, let filenameInArchive):
            if let filenameInArchive = filenameInArchive {
                return containerPath.appending(component: filenameInArchive)
            } else {
                throw DirectlyAccessibleResourceError.archiveFilenameNotSpecified(self)
            }
        }
    }
}
