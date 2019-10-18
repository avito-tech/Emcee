import Foundation

public final class FbXcTestPlanFinishedEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .testPlanFinished
    public let targetName: String  // e.g. FunctionalTests-Runner.app/PlugIns/FunctionalTests.xctest
    public let timestamp: TimeInterval
    public let bundleName: String  // e.g. FunctionalTests.xctest
    public let testType: String    // ui-test
    public let succeeded: Bool
    
    public init(
        targetName: String,
        timestamp: TimeInterval,
        bundleName: String,
        testType: String,
        succeeded: Bool
    ) {
        self.targetName = targetName
        self.timestamp = timestamp
        self.bundleName = bundleName
        self.testType = testType
        self.succeeded = succeeded
    }
    
    public var description: String {
        if succeeded {
            return "Test plan finished for bundle: \(bundleName)"
        } else {
            return "Test plan FAILED for bundle: \(bundleName)"
        }
    }
}
