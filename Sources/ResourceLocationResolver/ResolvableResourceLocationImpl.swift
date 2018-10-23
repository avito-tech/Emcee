import Foundation
import Models

public class ResolvableResourceLocationImpl: ResolvableResourceLocation {
    public let resourceLocation: ResourceLocation
    public let resolver: ResourceLocationResolver

    public init(resourceLocation: ResourceLocation, resolver: ResourceLocationResolver) {
        self.resourceLocation = resourceLocation
        self.resolver = resolver
    }
    
    public func resolve() throws -> ResolvingResult {
        return try resolver.resolvePath(resourceLocation: resourceLocation)
    }
}
