import Models
import Foundation

public class NonResolvableResourceLocation: ResolvableResourceLocation {
    public init() { }

    public var resourceLocation: ResourceLocation {
        return .remoteUrl(URL(string: "invalid://url")!)
    }

    enum `Error`: Swift.Error {
        case thisIsNonResolvableResourceLocation
    }
    public func resolve() throws -> ResolvingResult {
        throw Error.thisIsNonResolvableResourceLocation
    }
}
