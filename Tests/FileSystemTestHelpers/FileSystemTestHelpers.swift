import Foundation
import FileSystem
import PathLib

public class FakeCommonlyUsedPathsProvider: CommonlyUsedPathsProvider {
    public var applicationsProvider: ((domain: SearchDomain, create: Bool)) throws -> AbsolutePath
    public var cachesProvider: ((domain: SearchDomain, create: Bool)) throws -> AbsolutePath
    public var libraryProvider: ((domain: SearchDomain, create: Bool)) throws -> AbsolutePath
    
    public init(
        applicationsProvider: @escaping ((domain: SearchDomain, create: Bool)) throws -> AbsolutePath,
        cachesProvider: @escaping ((domain: SearchDomain, create: Bool)) throws -> AbsolutePath,
        libraryProvider: @escaping ((domain: SearchDomain, create: Bool)) throws -> AbsolutePath
    ) {
        self.applicationsProvider = applicationsProvider
        self.cachesProvider = cachesProvider
        self.libraryProvider = libraryProvider
    }
    
    public func applications(inDomain: SearchDomain, create: Bool) throws -> AbsolutePath {
        return try applicationsProvider((domain: inDomain, create: create))
    }
    
    public func caches(inDomain: SearchDomain, create: Bool) throws -> AbsolutePath {
        return try cachesProvider((domain: inDomain, create: create))
    }
    
    public func library(inDomain: SearchDomain, create: Bool) throws -> AbsolutePath {
        return try libraryProvider((domain: inDomain, create: create))
    }
}
