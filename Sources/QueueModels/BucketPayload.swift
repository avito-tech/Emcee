import Foundation

public enum BucketPayload: Hashable {
    case runIosTests(RunIosTestsPayload)
}

extension BucketPayload {
    public func cast<T>(_ type: T.Type) throws -> T {
        switch self {
        case .runIosTests(let runIosTestsPayload):
            return try cast(containedValue: runIosTestsPayload, to: type)
        }
    }
    
    public struct CastingError<V, T>: Error, CustomStringConvertible {
        public let containedValue: V
        public let targetType: T
        
        public var description: String {
            "Can't cast value \(containedValue) to type \(T.self)"
        }
    }
    
    private func cast<V, T>(containedValue: V, to type: T.Type) throws -> T {
        guard let result = containedValue as? T else {
            throw CastingError(containedValue: containedValue, targetType: T.self)
        }
        return result
    }
}

extension BucketPayload: CustomStringConvertible {
    public var description: String {
        switch self {
        case .runIosTests(let runIosTestsPayload):
            return runIosTestsPayload.description
        }
    }
}

extension BucketPayload: Codable {
    private enum BucketPayloadType: String, Codable {
        case runIosTests
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
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let bucketPayloadType = try container.decode(BucketPayloadType.self, forKey: .payloadType)
        switch bucketPayloadType {
        case .runIosTests:
            self = .runIosTests(try container.decode(RunIosTestsPayload.self, forKey: .payload))
        }
    }
}
