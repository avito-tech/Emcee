import Foundation
import ResourceLocation
import TypedResourceLocation

public protocol ResourceLocationResolver {
    func resolvePath(resourceLocation: ResourceLocation) throws -> ResolvingResult
    
    func evictOldCache(cacheElementTimeToLive: TimeInterval, maximumCacheSize: Int)
}

public extension ResourceLocationResolver {
    func resolvable(resourceLocation: ResourceLocation) -> ResolvableResourceLocation {
        return ResolvableResourceLocationImpl(resourceLocation: resourceLocation, resolver: self)
    }
    
    func resolvable(withRepresentable representable: RepresentableByResourceLocation) -> ResolvableResourceLocation {
        return resolvable(resourceLocation: representable.resourceLocation)
    }
}
