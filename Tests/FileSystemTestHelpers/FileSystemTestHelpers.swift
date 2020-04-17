import Foundation
import FileSystem
import PathLib

public class FakeCommonlyUsedPathsProvider: CommonlyUsedPathsProvider {
    public var cachesProvider: ((domain: SearchDomain, create: Bool)) throws -> AbsolutePath
    public var libraryProvider: ((domain: SearchDomain, create: Bool)) throws -> AbsolutePath
    
    public init(
        cachesProvider: @escaping ((domain: SearchDomain, create: Bool)) throws -> AbsolutePath,
        libraryProvider: @escaping ((domain: SearchDomain, create: Bool)) throws -> AbsolutePath
    ) {
        self.cachesProvider = cachesProvider
        self.libraryProvider = libraryProvider
    }
    
    public func caches(inDomain: SearchDomain, create: Bool) throws -> AbsolutePath {
        return try cachesProvider((domain: inDomain, create: create))
    }
    
    public func library(inDomain: SearchDomain, create: Bool) throws -> AbsolutePath {
        return try libraryProvider((domain: inDomain, create: create))
    }
}
