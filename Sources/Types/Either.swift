import Foundation

public enum Either<Left, Right>: CustomStringConvertible {
    case left(Left)
    case right(Right)

    public init(_ value: Left) {
        self = .left(value)
    }

    public init(_ value: Right) {
        self = .right(value)
    }

    public var description: String {
        switch self {
        case .left(let value):
            return "Result.left(\(value)))"
        case .right(let value):
            return "Result.right(\(value))"
        }
    }
    
    public var isLeft: Bool {
        switch self {
        case .left: return true
        case .right: return false
        }
    }
    
    public var isRight: Bool {
        return !isLeft
    }
    
    public var left: Left? {
        switch self {
        case .left(let value):
            return value
        case .right:
            return nil
        }
    }
    
    public var right: Right? {
        switch self {
        case .right(let value):
            return value
        case .left:
            return nil
        }
    }
}

public extension Either where Right: Error {
    static func success(_ value: Left) -> Either {
        return Either.left(value)
    }

    static func error(_ error: Right) -> Either {
        return Either.right(error)
    }

    init(value: Left) {
        self = .left(value)
    }

    init(error: Right) {
        self = .right(error)
    }

    func dematerialize() throws -> Left {
        switch self {
        case .left(let value):
            return value
        case .right(let error):
            throw error
        }
    }
    
    func mapResult<NewResult>(_ transform: (Left) -> NewResult) -> Either<NewResult, Error> {
        do {
            let result = try dematerialize()
            return .success(transform(result))
        } catch {
            return .error(error)
        }
    }
    
    var isSuccess: Bool { return isLeft }
    var isError: Bool { return isRight }
}

extension Either: Equatable where Left: Equatable, Right: Equatable {}

extension Either: Codable where Left: Codable, Right: Codable {
    private enum CodingKeys: String, CodingKey {
        case value, caseId
    }

    private enum CaseId: String, Codable {
        case left, right
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .left(let value):
            try container.encode(CaseId.left, forKey: CodingKeys.caseId)
            try container.encode(value, forKey: CodingKeys.value)
        case .right(let value):
            try container.encode(CaseId.right, forKey: CodingKeys.caseId)
            try container.encode(value, forKey: CodingKeys.value)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: CodingKeys.caseId)
        switch caseId {
        case .left:
            self = .left(try container.decode(Left.self, forKey: CodingKeys.value))
        case .right:
            self = .right(try container.decode(Right.self, forKey: CodingKeys.value))
        }
    }
}
