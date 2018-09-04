import Foundation
import Ansi

public protocol CommonTestFields {
    var className: String { get }
    var methodName: String { get }
}

public protocol WithTestName {
    var testName: String { get }
}

// This is not needed to be used outside this file yet.
fileprivate class FbXcTestEventClassNameParser {
    private init() {}
    
    static func testNameFromCommonTestFields(_ fields: CommonTestFields) -> String {
        return testNameFromClassName(fields.className, fields.methodName)
    }
    
    private static func testNameFromClassName(_ className: String, _ methodName: String) -> String {
        let components = className.components(separatedBy: ".")
        guard components.count == 2 else { return "\(className)/\(methodName)" }
        // first component contains a target name, second - class name
        return "\(components[1])/\(methodName)"
    }
}

public enum FbXcTestEventName: String, Codable {
    case testSuiteStarted = "begin-test-suite"
    case testSuiteFinished = "end-test-suite"
    case testStarted = "begin-test"
    case testFinished = "end-test"
    case testPlanStarted = "begin-ocunit"
    case testPlanFinished = "end-ocunit"
    case testPlanError = "test-plan-error"
    case testOutput = "test-output"
    case testIsWaitingForDebugger = "begin-status"
    case testDetectedDebugger = "end-status"
    case videoRecordingFinished = "video-recording-finished"
    case osLogSaved = "os-log-saved"
    case runnerAppLogSaved = "runner-app-log-saved"
    case didCopyTestArtifact = "copy-test-artifact"
}

public final class FbXcTestEvent: Decodable {
    public let event: FbXcTestEventName
    
    public init(event: FbXcTestEventName) {
        self.event = event
    }
}

// MARK: - Test Suite Events

public final class TestSuiteStartedEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .testSuiteStarted
    public let suite: String
    public let timestamp: TimeInterval
    
    public init(suite: String, timestamp: TimeInterval) {
        self.suite = suite
        self.timestamp = timestamp
    }
    
    public var description: String {
        return "Started suite \(suite)"
    }
}

public final class TestSuiteFinishedEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .testSuiteFinished
    public let suite: String  // e.g. AdvertisementTests_43915, FunctionalTests.xctest, "All Tests", "Selected Tests"
    public let testCaseCount: Int
    public let totalFailureCount: Int
    public let totalDuration: TimeInterval
    public let unexpectedExceptionCount: Int
    public let timestamp: TimeInterval
    public let testDuration: TimeInterval
    
    public init(
        suite: String,
        testCaseCount: Int,
        totalFailureCount: Int,
        totalDuration: TimeInterval,
        unexpectedExceptionCount: Int,
        timestamp: TimeInterval,
        testDuration: TimeInterval) {
        self.suite = suite
        self.testCaseCount = testCaseCount
        self.totalFailureCount = totalFailureCount
        self.totalDuration = totalDuration
        self.unexpectedExceptionCount = unexpectedExceptionCount
        self.timestamp = timestamp
        self.testDuration = testDuration
    }
    
    public var description: String {
        return """
        Finished suite \(suite),
        ran \(testCaseCount) tests, failed \(totalFailureCount) tests,
        duration \(Int(totalDuration))
        """
    }
}

// MARK: - Test Events

public final class TestStartedEvent: CustomStringConvertible, CommonTestFields, WithTestName, Codable {
    public let event: FbXcTestEventName = .testStarted
    public let test: String          // e.g. -[FunctionalTests.MainPageTest_100856 test_dataSet0]
    public let className: String     // e.g. FunctionalTests.MainPageTest_100856
    public let methodName: String    // test_dataSet0
    public let timestamp: TimeInterval
    public let hostName: String?
    public let processId: Int32?
    public let simulatorId: String?
    
    public init(
        test: String,
        className: String,
        methodName: String,
        timestamp: TimeInterval,
        hostName: String? = nil,
        processId: Int32? = nil,
        simulatorId: String? = nil) {
        self.test = test
        self.className = className
        self.methodName = methodName
        self.timestamp = timestamp
        self.hostName = hostName
        self.processId = processId
        self.simulatorId = simulatorId
    }
    
    public func withProcessId(newProcessId: Int32) -> TestStartedEvent {
        return TestStartedEvent(
            test: test,
            className: className,
            methodName: methodName,
            timestamp: timestamp,
            hostName: hostName,
            processId: newProcessId,
            simulatorId: simulatorId)
    }
    
    public func withSimulatorId(newSimulatorId: String) -> TestStartedEvent {
        return TestStartedEvent(
            test: test,
            className: className,
            methodName: methodName,
            timestamp: timestamp,
            hostName: hostName,
            processId: processId,
            simulatorId: newSimulatorId)
    }
    
    public func witHostName(newHostName: String) -> TestStartedEvent {
        return TestStartedEvent(
            test: test,
            className: className,
            methodName: methodName,
            timestamp: timestamp,
            hostName: newHostName,
            processId: processId,
            simulatorId: simulatorId)
    }
    
    public var testName: String {
        return FbXcTestEventClassNameParser.testNameFromCommonTestFields(self)
    }
    
    public var description: String {
        return "Started test \(testName)"
    }
}

public final class TestFinishedEvent: CustomStringConvertible, CommonTestFields, WithTestName, Codable {
    public let event: FbXcTestEventName = .testFinished
    public let test: String            // e.g. -[FunctionalTests.MainPageTest_100856 test_dataSet0]
    public let result: String          // e.g. "success" or "failure"
    public let className: String       // e.g. FunctionalTests.MainPageTest_100856
    public let methodName: String      // e.g. test_dataSet0
    public let totalDuration: TimeInterval
    public let exceptions: [TestExceptionEvent]
    public let succeeded: Bool
    public let output: String
    public let logs: [String]
    public let timestamp: TimeInterval
    
    public init(
        test: String,
        result: String,
        className: String,
        methodName: String,
        totalDuration: TimeInterval,
        exceptions: [TestExceptionEvent],
        succeeded: Bool,
        output: String,
        logs: [String],
        timestamp: TimeInterval)
    {
        self.test = test
        self.result = result
        self.className = className
        self.methodName = methodName
        self.totalDuration = totalDuration
        self.exceptions = exceptions
        self.succeeded = succeeded
        self.output = output
        self.logs = logs
        self.timestamp = timestamp
    }
    
    public var testName: String {
        return FbXcTestEventClassNameParser.testNameFromCommonTestFields(self)
    }
    
    public var description: String {
        return "Finished test \(testName), " +
            (succeeded
                ? "test passed".with(consoleColor: .boldGreen)
                : "test failed".with(consoleColor: .boldRed)) +
        ", \(Int(totalDuration)) sec"
    }
}

// MARK: - Test Plan Events

public final class TestPlanStartedEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .testPlanStarted
    public let targetName: String  // e.g. FunctionalTests-Runner.app/PlugIns/FunctionalTests.xctest
    public let timestamp: TimeInterval
    public let bundleName: String  // e.g. FunctionalTests.xctest
    public let testType: String    // ui-test
    
    public init(targetName: String, timestamp: TimeInterval, bundleName: String, testType: String) {
        self.targetName = targetName
        self.timestamp = timestamp
        self.bundleName = bundleName
        self.testType = testType
    }
    
    public var description: String {
        return "Test plan started for bundle: \(bundleName)"
    }
}

public final class TestPlanFinishedEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .testPlanFinished
    public let targetName: String  // e.g. FunctionalTests-Runner.app/PlugIns/FunctionalTests.xctest
    public let timestamp: TimeInterval
    public let bundleName: String  // e.g. FunctionalTests.xctest
    public let testType: String    // ui-test
    public let succeeded: Bool
    
    public init(targetName: String, timestamp: TimeInterval, bundleName: String, testType: String, succeeded: Bool) {
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

public final class TestPlanErrorEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .testPlanError
    public let message: String
    public let timestamp: TimeInterval = Date().timeIntervalSince1970
    
    public init(message: String) {
        self.message = message
    }
    
    public var description: String {
        return "Test plan failed with message: \(message)"
    }
}

public final class TestExceptionEvent: Codable {
    public let reason: String
    public let filePathInProject: String
    public let lineNumber: Int32
    
    public init(reason: String, filePathInProject: String, lineNumber: Int32) {
        self.reason = reason
        self.filePathInProject = filePathInProject
        self.lineNumber = lineNumber
    }
}

public final class TestOutputEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .testOutput
    public let output: String
    
    public init(output: String) {
        self.output = output
    }
    
    public var description: String {
        return "Test had output: \(output)"
    }
}

public final class TestIsWaitingForDebuggerEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .testIsWaitingForDebugger
    public let pid: Int32
    public let message: String
    
    public init(pid: Int32, message: String) {
        self.pid = pid
        self.message = message
    }
    
    public var description: String {
        return "Test is waiting for debugger to attach for pid \(pid): \(message)"
    }
}

public final class TestDetectedDebuggerEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .testDetectedDebugger
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
    
    public var description: String {
        return "Test has detected a debugger: \(message)"
    }
}

public final class VideoRecordingFinishedEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .videoRecordingFinished
    public let videoRecordingPath: String
    
    public init(videoRecordingPath: String) {
        self.videoRecordingPath = videoRecordingPath
    }
    
    public var description: String {
        return "Video recording is available at: \(videoRecordingPath)"
    }
}

public final class OSLogSavedEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .osLogSaved
    public let osLogPath: String
    
    public init(osLogPath: String) {
        self.osLogPath = osLogPath
    }
    
    public var description: String {
        return "OS Log saved at path: \(osLogPath)"
    }
}

public final class RunnerAppLogSavedEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .runnerAppLogSaved
    public let path: String
    
    public init(path: String) {
        self.path = path
    }
    
    public var description: String {
        return "Runner app log saved at path: \(path)"
    }
}

public final class DidCopyTestArtifactEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .didCopyTestArtifact
    public let testArtifactFileName: String
    public let path: String
    
    public init(testArtifactFileName: String, path: String) {
        self.testArtifactFileName = testArtifactFileName
        self.path = path
    }
    
    public var description: String {
        return "Copied test artifact: \(testArtifactFileName), path: \(path)"
    }
    
    private enum CodingKeys: String, CodingKey {
        case testArtifactFileName = "test_artifact_file_name"
        case path 
    }
}

// MARK: Error Streaming

public struct GenericErrorEvent: Decodable {
    public let errorOrigin: String
    public let domain: String
    public let code: Int
    public let text: String?

    public init(errorOrigin: String, domain: String, code: Int, text: String?) {
        self.errorOrigin = errorOrigin
        self.domain = domain
        self.code = code
        self.text = text
    }
}
