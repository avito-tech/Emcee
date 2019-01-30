import Foundation

public enum RunnerEvent: Equatable {
    case willRun(testEntries: [TestEntry], testContext: TestContext)
    case didRun(results: [TestEntryResult], testContext: TestContext)
    
    public var testContext: TestContext {
        switch self {
        case .willRun(_, let testContext):
            return testContext
        case .didRun(_, let testContext):
            return testContext
        }
    }
}

extension RunnerEvent: Codable {
    private enum CodingKeys: CodingKey {
        case eventType
        case testEntries
        case testContext
        case results
    }
    
    private enum EventType: String, Codable {
        case willRun
        case didRun
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let eventType = try container.decode(EventType.self, forKey: .eventType)
        
        switch eventType {
        case .willRun:
            let testEntries = try container.decode([TestEntry].self, forKey: .testEntries)
            let testContext = try container.decode(TestContext.self, forKey: .testContext)
            self = .willRun(testEntries: testEntries, testContext: testContext)
        case .didRun:
            let results = try container.decode([TestEntryResult].self, forKey: .results)
            let testContext = try container.decode(TestContext.self, forKey: .testContext)
            self = .didRun(results: results, testContext: testContext)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .willRun(let testEntries, let testContext):
            try container.encode(EventType.willRun, forKey: .eventType)
            try container.encode(testEntries, forKey: .testEntries)
            try container.encode(testContext, forKey: .testContext)
        case .didRun(let results, let testContext):
            try container.encode(EventType.didRun, forKey: .eventType)
            try container.encode(results, forKey: .results)
            try container.encode(testContext, forKey: .testContext)
        }
    }
}
