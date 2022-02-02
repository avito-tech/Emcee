import Foundation

public struct LogEntryCoordinate: Hashable, Codable {
    public let name: String
    public let value: String?
    
    public init(
        name: String,
        value: String? = nil
    ) {
        self.name = name
        self.value = value
    }
}
