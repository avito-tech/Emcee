import Foundation

public enum BucketPayload: Codable, CustomStringConvertible, Hashable {
    case runIosTests(RunIosTestsPayload)
    case ping

    public var description: String {
        switch self {
        case .runIosTests(let runIosTestsPayload):
            return runIosTestsPayload.description
        case .ping:
            return "ping"
        }
    }

    private enum BucketPayloadType: String, Codable {
        case runIosTests
        case ping
    }
    
    private enum Keys: String, CodingKey {
        case payloadType
        case payload
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        switch self {
        case .runIosTests(let runIosTestsPayload):
            try container.encode(BucketPayloadType.runIosTests, forKey: .payloadType)
            try container.encode(runIosTestsPayload, forKey: .payload)
        case .ping:
            try container.encode(BucketPayloadType.ping, forKey: .payloadType)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let bucketPayloadType = try container.decode(BucketPayloadType.self, forKey: .payloadType)
        switch bucketPayloadType {
        case .runIosTests:
            self = .runIosTests(try container.decode(RunIosTestsPayload.self, forKey: .payload))
        case .ping:
            self = .ping
        }
    }
}
