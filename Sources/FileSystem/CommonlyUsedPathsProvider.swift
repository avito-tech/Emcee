import Foundation
import PathLib

public enum SearchDomain {
    case user
    case local
    case network
    case system
}

public protocol CommonlyUsedPathsProvider {
    func library(inDomain: SearchDomain, create: Bool) throws -> AbsolutePath
    func caches(inDomain: SearchDomain, create: Bool) throws -> AbsolutePath
}
