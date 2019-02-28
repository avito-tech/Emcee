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
    
    public static func withOptional<T>(_ resourceLocation: ResourceLocation?) -> TypedResourceLocation<T>? {
        if let resourceLocation = resourceLocation {
            return TypedResourceLocation<T>(resourceLocation)
        } else {
            return nil
        }
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
