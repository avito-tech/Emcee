import Foundation

public struct WorkerCapability: Codable, Hashable, CustomStringConvertible {
    public let name: WorkerCapabilityName
    public let value: String
    
    public init(name: WorkerCapabilityName, value: String) {
        self.name = name
        self.value = value
    }
    
    public var description: String {
        "<\(type(of: self)) name: \(name.value), value: \(value)>"
    }
}
