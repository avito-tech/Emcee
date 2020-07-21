import Foundation
import PathLib

public final class DefaultCommonlyUsedPathsProvider: CommonlyUsedPathsProvider {
    private let fileManager: FileManager
    
    public init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    public func applications(inDomain domain: SearchDomain, create: Bool) throws -> AbsolutePath {
        return AbsolutePath(
            try fileManager.url(
                for: .applicationDirectory,
                in: domain.mask,
                appropriateFor: nil,
                create: create
            )
        )
    }
    
    public func caches(inDomain domain: SearchDomain, create: Bool) throws -> AbsolutePath {
        return AbsolutePath(
            try fileManager.url(
                for: .cachesDirectory,
                in: domain.mask,
                appropriateFor: nil,
                create: create
            )
        )
    }
    
    public func library(inDomain domain: SearchDomain, create: Bool) throws -> AbsolutePath {
        return AbsolutePath(
            try fileManager.url(
                for: .libraryDirectory,
                in: domain.mask,
                appropriateFor: nil,
                create: create
            )
        )
    }
}

extension SearchDomain {
    var mask: FileManager.SearchPathDomainMask {
        switch self {
        case .local:
            return .localDomainMask
        case .user:
            return .userDomainMask
        case .network:
            return .networkDomainMask
        case .system:
            return .systemDomainMask
        }
    }
}
