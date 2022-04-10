import Foundation
import SocketModels
 
public struct PortRange: Codable, CustomStringConvertible, Hashable {
    public let from: SocketModels.Port
    public let to: SocketModels.Port
    
    public struct MisconfigurationError: Error, CustomStringConvertible {
        public let from: SocketModels.Port
        public let to: SocketModels.Port

        public var description: String {
            "Port range misconfigured: `from` port \(from) should be less than or equal to `to` port \(to)"
        }
    }
    
    public var description: String {
        "[\(from)...\(to)]"
    }
    
    public var closedRange: ClosedRange<SocketModels.Port> {
        from...to
    }
    
    public init(
        from: SocketModels.Port,
        to: SocketModels.Port
    ) throws {
        guard from <= to else {
            throw MisconfigurationError(from: from, to: to)
        }
        
        self.from = from
        self.to = to
    }
    
    public init(from: SocketModels.Port, rangeLength: Int) {
        self.from = from
        self.to = SocketModels.Port(value: from.value + rangeLength)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.from = try container.decode(Port.self, forKey: .from)
        self.to = try container.decode(Port.self, forKey: .to)
        
        guard from <= to else {
            throw MisconfigurationError(from: from, to: to)
        }
    }
}
