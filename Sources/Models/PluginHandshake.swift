import Foundation

public final class PluginHandshakeRequest: Codable {
    public let pluginIdentifier: String

    public init(pluginIdentifier: String) {
        self.pluginIdentifier = pluginIdentifier
    }
}

public enum PluginHandshakeAcknowledgement: Codable, CustomStringConvertible {
    case successful
    case error(String)
    
    private enum CodingKeys: String, CodingKey {
        case caseId
        case message
    }
    
    private enum CaseId: String, Codable {
        case successful
        case error
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)
        
        switch caseId {
        case .successful:
            self = .successful
        case .error:
            let message = try container.decode(String.self, forKey: .message)
            self = .error(message)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .successful:
            try container.encode(CaseId.successful, forKey: .caseId)
        case .error(let message):
            try container.encode(CaseId.error, forKey: .caseId)
            try container.encode(message, forKey: .message)
        }
    }
    
    public var description: String {
        switch self {
        case .successful:
            return "<successful acknowledgement>"
        case .error(let message):
            return "<acknowledgement error: '\(message)'>"
        }
    }
}
