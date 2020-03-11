import Foundation
import Models

public enum QueueVersionResponse: Codable, Equatable {
    case queueVersion(Version)
    
    enum CodingKeys: CodingKey {
        case responseType
        case version
    }
    
    private enum CaseId: String, Codable {
        case queueVersion
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .queueVersion(let version):
            try container.encode(CaseId.queueVersion, forKey: .responseType)
            try container.encode(version, forKey: .version)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let responseType = try container.decode(CaseId.self, forKey: .responseType)
        switch responseType {
        case .queueVersion:
            self = .queueVersion(try container.decode(Version.self, forKey: .version))
        }
    }
}
