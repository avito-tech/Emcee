import Foundation

public struct SocketAddress: Codable, CustomStringConvertible, Hashable {
    public let host: String
    public let port: Port
    
    public enum ParseError: Error, CustomStringConvertible {
        case unsupportedFormat(String)
        
        public var description: String {
            switch self {
            case .unsupportedFormat(let input):
                return "Unable to parse socket address from input '\(input)'. Expected format: hostname:1234"
            }
        }
    }

    public init(host: String, port: Port) {
        self.host = host
        self.port = port
    }
    
    public static func from(string: String) throws -> SocketAddress {
        let components = string.split(separator: ":")
        guard components.count == 2, let port = Int(components[1]) else {
            throw ParseError.unsupportedFormat(string)
        }
        return SocketAddress(
            host: String(components[0]),
            port: Port(value: port)
        )
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        let address = try SocketAddress.from(string: value)
        host = address.host
        port = address.port
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
    
    public var asString: String {
        return "\(host):\(port.value)"
    }
    
    public var description: String {
        return asString
    }
}
