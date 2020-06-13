public enum XCTestJsonEvent: Codable, Equatable {
    case beginTest(XCTestStartEvent)
    case testFailure(XCTestFailureEvent)
    case endTest(XCTestEndEvent)
    
    public enum CodingKeys: String, CodingKey {
        case beginTest
        case testFailure
        case endTest
    }
    
    struct UnknownEventType: Error {}
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys {
        case [.beginTest]:
            self = try .beginTest(container.decode(XCTestStartEvent.self, forKey: .beginTest))
        case [.testFailure]:
            self = try .testFailure(container.decode(XCTestFailureEvent.self, forKey: .testFailure))
        case [.endTest]:
            self = try .endTest(container.decode(XCTestEndEvent.self, forKey: .endTest))
        default:
            throw UnknownEventType()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .beginTest(testStart):
            try container.encode(testStart, forKey: .beginTest)
        case let .testFailure(testFailure):
            try container.encode(testFailure, forKey: .testFailure)
        case let .endTest(testEnd):
            try container.encode(testEnd, forKey: .endTest)
        }
    }
}

public struct XCTestStartEvent: Codable, Equatable {
    public let className: String
    public let methodName: String
    
    public init(className: String, methodName: String) {
        self.className = className
        self.methodName = methodName
    }
}

public struct XCTestFailureEvent: Codable, Equatable {
    public let file: String
    public let line: Int
    public let reason: String
    
    public init(file: String, line: Int, reason: String) {
        self.file = file
        self.line = line
        self.reason = reason
    }
}

public struct XCTestEndEvent: Codable, Equatable {
    public enum Result: String, Codable {
        case error
        case failure
        case success
    }
    
    public let className: String
    public let methodName: String
    public let result: Result
    public let totalDuration: Double
    
    public init(
        className: String,
        methodName: String,
        result: XCTestEndEvent.Result,
        totalDuration: Double
    ) {
        self.className = className
        self.methodName = methodName
        self.result = result
        self.totalDuration = totalDuration
    }
}
