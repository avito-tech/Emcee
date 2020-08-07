import Foundation

public indirect enum WorkerCapabilityConstraint: Codable, Hashable {
    case absent
    case equal(String)
    case lessThan(String)
    case greaterThan(String)
    case not(WorkerCapabilityConstraint)
    case all([WorkerCapabilityConstraint])
    case any([WorkerCapabilityConstraint])
    
    public func and(_ constraint: WorkerCapabilityConstraint) -> WorkerCapabilityConstraint {
        .all([self, constraint])
    }
    
    public func or(_ contraint: WorkerCapabilityConstraint) -> WorkerCapabilityConstraint {
        .any([self, contraint])
    }
    
    public static func lessThanOrEqualTo(_ value: String) -> WorkerCapabilityConstraint {
        .any([.equal(value), .lessThan(value)])
    }
    
    public static func greaterThanOrEqualTo(_ value: String) -> WorkerCapabilityConstraint {
        .any([.equal(value), .greaterThan(value)])
    }
    
    public static var present: WorkerCapabilityConstraint = .not(.absent)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }
    
    private enum TypeId: String, Codable {
        case missing
        case equal
        case lessThan
        case greaterThan
        case not
        case all
        case any
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(TypeId.self, forKey: .type)
        switch type {
        case .missing:
            self = .absent
        case .equal:
            self = .equal(try container.decode(String.self, forKey: .value))
        case .lessThan:
            self = .lessThan(try container.decode(String.self, forKey: .value))
        case .greaterThan:
            self = .greaterThan(try container.decode(String.self, forKey: .value))
        case .not:
            self = .not(try container.decode(WorkerCapabilityConstraint.self, forKey: .value))
        case .all:
            self = .all(try container.decode([WorkerCapabilityConstraint].self, forKey: .value))
        case .any:
            self = .any(try container.decode([WorkerCapabilityConstraint].self, forKey: .value))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .absent:
            try container.encode(TypeId.missing, forKey: .type)
        case .equal(let value):
            try container.encode(TypeId.equal, forKey: .type)
            try container.encode(value, forKey: .value)
        case .lessThan(let value):
            try container.encode(TypeId.lessThan, forKey: .type)
            try container.encode(value, forKey: .value)
        case .greaterThan(let value):
            try container.encode(TypeId.greaterThan, forKey: .type)
            try container.encode(value, forKey: .value)
        case .not(let constraint):
            try container.encode(TypeId.not, forKey: .type)
            try container.encode(constraint, forKey: .value)
        case .all(let constraints):
            try container.encode(TypeId.all, forKey: .type)
            try container.encode(constraints, forKey: .value)
        case .any(let constraints):
            try container.encode(TypeId.any, forKey: .type)
            try container.encode(constraints, forKey: .value)
        }
    }
}
