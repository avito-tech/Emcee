import ArgLib
import Foundation
import Models

extension TypedResourceLocation: ParsableArgument {
    public convenience init(argumentValue: String) throws {
        let resourceLocation = try ResourceLocation.from(argumentValue)
        self.init(resourceLocation)
    }
}

extension SocketAddress: ParsableArgument {
    public convenience init(argumentValue: String) throws {
        let parsedAddress = try SocketAddress.from(string: argumentValue)
        self.init(host: parsedAddress.host, port: parsedAddress.port)
    }
}

extension WorkerId: ParsableArgument {
    public convenience init(argumentValue: String) throws {
        self.init(value: argumentValue)
    }
}
