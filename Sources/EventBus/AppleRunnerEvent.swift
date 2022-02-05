import Foundation
import RunnerModels

public enum AppleRunnerEvent: Codable, Equatable, CustomStringConvertible {
    /// Event indicates that a set of tests will be run.
    case willRun(testEntries: [TestEntry], testContext: AppleTestContext)

    /// Event occurs after test starts.
    /// At this time there is no information about its result yet.
    /// This event will be triggered for each test from the set of tests which has started before.
    case testStarted(testEntry: TestEntry, testContext: AppleTestContext)
    
    /// Event occurs after test finishes. At this time only a limited test result information is available.
    /// At the moment of this event triggering, some tests still may be up to be executed by the test runner.
    /// This event will be triggered for each test from the set of tests which has started before.
    /// This event is not an appropriate place to process test results, because not all test results can be available, or test results may be not complete.
    case testFinished(testEntry: TestEntry, succeeded: Bool, testContext: AppleTestContext)
    
    /// This event indicates that test runner has finished running all tests from the test set it has been executing.
    /// At this point, all test results are final and contain maximum details test runner managed to obtain.
    /// This event is a good place to process test results.
    case didRun(results: [TestEntryResult], testContext: AppleTestContext)
    
    public var testContext: AppleTestContext {
        switch self {
        case .willRun(_, let testContext):
            return testContext
        case .didRun(_, let testContext):
            return testContext
        case .testStarted(_, let testContext):
            return testContext
        case .testFinished(_, _, let testContext):
            return testContext
        }
    }
    
    public var description: String {
        let eventName: String
        let testContext: AppleTestContext
        let additionalInfo: String
        
        switch self {
        case .willRun(let testEntries, let context):
            eventName = "willRun"
            testContext = context
            additionalInfo = "testEntries: " + testEntries.map { $0.description }.joined(separator: ", ")
        case .didRun(let results, let context):
            eventName = "didRun"
            testContext = context
            additionalInfo = "results: " + results.map { $0.description }.joined(separator: ", ")
        case .testStarted(let testEntry, let context):
            eventName = "testStarted"
            testContext = context
            additionalInfo = "testEntry: \(testEntry)"
        case .testFinished(let testEntry, let succeeded, let context):
            eventName = "testFinished"
            testContext = context
            additionalInfo = "testEntry: \(testEntry), \(succeeded ? "succeeded" : "failed")"
        }
        
        return "<\(type(of: self)) " + [eventName, String(describing: testContext), additionalInfo].joined(separator: ", ") + ">"
    }

    private enum CodingKeys: CodingKey {
        case eventType
        case succeeded
        case testEntries
        case testEntry
        case testContext
        case results
    }
    
    private enum EventType: String, Codable {
        case willRun
        case didRun
        case testStarted
        case testFinished
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let eventType = try container.decode(EventType.self, forKey: .eventType)
        
        switch eventType {
        case .willRun:
            let testEntries = try container.decode([TestEntry].self, forKey: .testEntries)
            let testContext = try container.decode(AppleTestContext.self, forKey: .testContext)
            self = .willRun(testEntries: testEntries, testContext: testContext)
        case .didRun:
            let results = try container.decode([TestEntryResult].self, forKey: .results)
            let testContext = try container.decode(AppleTestContext.self, forKey: .testContext)
            self = .didRun(results: results, testContext: testContext)
        case .testStarted:
            let testEntry = try container.decode(TestEntry.self, forKey: .testEntry)
            let testContext = try container.decode(AppleTestContext.self, forKey: .testContext)
            self = .testStarted(testEntry: testEntry, testContext: testContext)
        case .testFinished:
            let testEntry = try container.decode(TestEntry.self, forKey: .testEntry)
            let testContext = try container.decode(AppleTestContext.self, forKey: .testContext)
            let succeeded = try container.decode(Bool.self, forKey: .succeeded)
            self = .testFinished(testEntry: testEntry, succeeded: succeeded, testContext: testContext)
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
        case .testStarted(let testEntry, let testContext):
            try container.encode(EventType.testStarted, forKey: .eventType)
            try container.encode(testEntry, forKey: .testEntry)
            try container.encode(testContext, forKey: .testContext)
        case .testFinished(let testEntry, let succeeded, let testContext):
            try container.encode(EventType.testFinished, forKey: .eventType)
            try container.encode(testEntry, forKey: .testEntry)
            try container.encode(succeeded, forKey: .succeeded)
            try container.encode(testContext, forKey: .testContext)
        }
    }
}
