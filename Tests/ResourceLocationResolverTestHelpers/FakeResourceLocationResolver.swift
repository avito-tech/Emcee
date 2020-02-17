import Foundation
import Models
import ResourceLocation
import ResourceLocationResolver

public final class FakeResourceLocationResolver: ResourceLocationResolver {
    public var resolvingResult: ResolvingResult
    public var resolveError: Error?
    
    public struct SomeError: Error, CustomStringConvertible {
        public let description = "some error happened"
        public init() {}
    }
    
    public static func throwing() -> FakeResourceLocationResolver {
        let resolver = resolvingToTempFolder()
        resolver.throwOnResolve()
        return resolver
    }
    
    public static func resolvingToTempFolder() -> FakeResourceLocationResolver {
        return FakeResourceLocationResolver(
            resolvingResult: .directlyAccessibleFile(path: NSTemporaryDirectory())
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
            return ResolvingResult.directlyAccessibleFile(path: path)
        case .remoteUrl:
            return resolvingResult
        }
    }
}
