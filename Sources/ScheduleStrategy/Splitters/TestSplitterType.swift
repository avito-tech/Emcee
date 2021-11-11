import Foundation

public enum TestSplitterType: Hashable, Codable {
    case individual
    case equallyDivided
    case progressive
    case unsplit
    case fixedBucketSize(Int)
    
    private enum TypeName: String, Codable {
        case individual
        case equallyDivided
        case progressive
        case unsplit
        case fixedBucketSize
    }
    
    private enum Keys: String, CodingKey {
        case type
        case size
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        switch self {
        case .individual:
            try container.encode(TypeName.individual, forKey: .type)
        case .equallyDivided:
            try container.encode(TypeName.equallyDivided, forKey: .type)
        case .progressive:
            try container.encode(TypeName.progressive, forKey: .type)
        case .unsplit:
            try container.encode(TypeName.unsplit, forKey: .type)
        case .fixedBucketSize(let size):
            try container.encode(TypeName.fixedBucketSize, forKey: .type)
            try container.encode(size, forKey: .size)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let typeName = try container.decode(TypeName.self, forKey: .type)
        
        switch typeName {
        case .individual:
            self = .individual
        case .equallyDivided:
            self = .equallyDivided
        case .progressive:
            self = .progressive
        case .unsplit:
            self = .unsplit
        case .fixedBucketSize:
            self = .fixedBucketSize(try container.decode(Int.self, forKey: .size))
        }
    }
}
