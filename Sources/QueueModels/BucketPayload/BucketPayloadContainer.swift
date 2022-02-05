import Foundation

public enum BucketPayloadContainer: Codable, CustomStringConvertible, Hashable {
    case runIosTests(RunAppleTestsPayload)
    case runAndroidTests(RunAndroidTestsPayload)
    
    public var payloadWithTests: BucketPayloadWithTests {
        switch self {
        case .runIosTests(let runIosTestsPayload):
            return runIosTestsPayload
        case .runAndroidTests(let runAndroidTestsPayload):
            return runAndroidTestsPayload
        }
    }

    public var description: String {
        switch self {
        case .runIosTests(let runIosTestsPayload):
            return runIosTestsPayload.description
        case .runAndroidTests(let runAndroidTestsPayload):
            return runAndroidTestsPayload.description
        }
    }

    private enum BucketPayloadType: String, Codable {
        case runIosTests
        case runAndroidTests
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
        case .runAndroidTests(let runAndroidTestsPayload):
            try container.encode(BucketPayloadType.runAndroidTests, forKey: .payloadType)
            try container.encode(runAndroidTestsPayload, forKey: .payload)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let bucketPayloadType = try container.decode(BucketPayloadType.self, forKey: .payloadType)
        switch bucketPayloadType {
        case .runIosTests:
            self = .runIosTests(try container.decode(RunAppleTestsPayload.self, forKey: .payload))
        case .runAndroidTests:
            self = .runAndroidTests(try container.decode(RunAndroidTestsPayload.self, forKey: .payload))
        }
    }
}
