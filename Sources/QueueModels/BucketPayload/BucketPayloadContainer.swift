import Foundation

public enum BucketPayloadContainer: Codable, CustomStringConvertible, Hashable {
    case runAppleTests(RunAppleTestsPayload)
    case runAndroidTests(RunAndroidTestsPayload)
    
    public var payloadWithTests: BucketPayloadWithTests {
        switch self {
        case .runAppleTests(let runAppleTestsPayload):
            return runAppleTestsPayload
        case .runAndroidTests(let runAndroidTestsPayload):
            return runAndroidTestsPayload
        }
    }

    public var description: String {
        switch self {
        case .runAppleTests(let runAppleTestsPayload):
            return runAppleTestsPayload.description
        case .runAndroidTests(let runAndroidTestsPayload):
            return runAndroidTestsPayload.description
        }
    }

    private enum BucketPayloadType: String, Codable {
        case runAppleTests
        case runAndroidTests
    }
    
    private enum Keys: String, CodingKey {
        case payloadType
        case payload
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        switch self {
        case .runAppleTests(let runAppleTestsPayload):
            try container.encode(BucketPayloadType.runAppleTests, forKey: .payloadType)
            try container.encode(runAppleTestsPayload, forKey: .payload)
        case .runAndroidTests(let runAndroidTestsPayload):
            try container.encode(BucketPayloadType.runAndroidTests, forKey: .payloadType)
            try container.encode(runAndroidTestsPayload, forKey: .payload)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let bucketPayloadType = try container.decode(BucketPayloadType.self, forKey: .payloadType)
        switch bucketPayloadType {
        case .runAppleTests:
            self = .runAppleTests(try container.decode(RunAppleTestsPayload.self, forKey: .payload))
        case .runAndroidTests:
            self = .runAndroidTests(try container.decode(RunAndroidTestsPayload.self, forKey: .payload))
        }
    }
}
