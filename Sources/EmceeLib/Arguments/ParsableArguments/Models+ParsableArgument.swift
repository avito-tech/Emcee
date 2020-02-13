import ArgLib
import Foundation
import Models
import QueueModels

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

extension Priority: ParsableArgument {
    public convenience init(argumentValue: String) throws {
        try self.init(intValue: try UInt(argumentValue: argumentValue))
    }
}

extension JobId: ParsableArgument {
    public convenience init(argumentValue: String) throws {
        self.init(value: argumentValue)
    }
}
