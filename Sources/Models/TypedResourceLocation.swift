import Foundation

public protocol ResourceLocationType {
    static var name: String { get }
}

/// This is just a wrapper around ResourceLocation, but it provides a type safety for it
public final class TypedResourceLocation<T: ResourceLocationType>: Codable, Hashable, CustomStringConvertible, RepresentableByResourceLocation {
    public let resourceLocation: ResourceLocation
    
    public init(_ resourceLocation: ResourceLocation) {
        self.resourceLocation = resourceLocation
    }

    public init?(_ resourceLocation: ResourceLocation?) {
        guard let resourceLocation = resourceLocation else {
            return nil
        }

        self.resourceLocation = resourceLocation
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        resourceLocation = try container.decode(ResourceLocation.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(resourceLocation)
    }
    
    public var description: String {
        return "<\(T.name): \(resourceLocation)>"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(resourceLocation)
    }
    
    public static func == (left: TypedResourceLocation<T>, right: TypedResourceLocation<T>) -> Bool {
        return left.resourceLocation == right.resourceLocation
    }
}
