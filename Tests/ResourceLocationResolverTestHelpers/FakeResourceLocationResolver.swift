import Foundation
import PathLib
import ResourceLocation
import ResourceLocationResolver

public final class FakeResourceLocationResolver: ResourceLocationResolver {
    public var resolvingResult: ResolvingResult
    public var resolveError: Error?
    
    public struct SomeError: Error, CustomStringConvertible {
        public let description = "FakeResourceLocationResolver is set to throw an error on resolve, so this error has been thrown"
        public init() {}
    }
    
    public static func throwing() -> FakeResourceLocationResolver {
        let resolver = resolvingTo(path: AbsolutePath.root)
        resolver.throwOnResolve()
        return resolver
    }
    
    public static func resolvingTo(
        path: AbsolutePath
    ) -> FakeResourceLocationResolver {
        return FakeResourceLocationResolver(
            resolvingResult: .directlyAccessibleFile(path: path)
        )
    }

    public init(resolvingResult: ResolvingResult) {
        self.resolvingResult = resolvingResult
    }
    
    public func throwOnResolve() {
        resolveError = SomeError()
    }
    
    public func resolveWithResult(resolvingResult: ResolvingResult) {
        resolveError = nil
        self.resolvingResult = resolvingResult
    }
    
    public func resolvePath(resourceLocation: ResourceLocation) throws -> ResolvingResult {
        if let error = resolveError {
            throw error
        }
        switch resourceLocation {
        case .localFilePath(let path):
            return ResolvingResult.directlyAccessibleFile(path: AbsolutePath(path))
        case .remoteUrl:
            return resolvingResult
        }
    }
    
    public func evictOldCache(cacheElementTimeToLive: TimeInterval, maximumCacheSize: Int) {
        
    }
}
