import Models
import Foundation

class NonResolvableResourceLocation: ResolvableResourceLocation {
    var resourceLocation: ResourceLocation {
        return .remoteUrl(URL(string: "invalid://url")!)
    }

    enum `Error`: Swift.Error {
        case thisIsNonResolvableResourceLocation
    }
    func resolve() throws -> ResolvingResult {
        throw Error.thisIsNonResolvableResourceLocation
    }
}
