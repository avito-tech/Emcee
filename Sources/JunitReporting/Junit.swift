import Foundation

public struct JunitTestCaseFailure {
    public let reason: String        // "Test failed because of blah"
    public let fileLine: String      // File.swift:42

    public init(reason: String, fileLine: String) {
        self.reason = reason
        self.fileLine = fileLine
    }
}

public struct JunitTestCase {
    public let className: String         // FunctionalTests.AbuseTests_91953
    public let name: String              // test, testDataSet0
    public let timestamp: TimeInterval   // when the test was executed, current timezone will be used
    public let time: TimeInterval        // Time taken (in seconds) to execute the tests in the suite
    public let hostname: String
    public let isFailure: Bool
    public let failures: [JunitTestCaseFailure]

    public init(
        className: String,
        name: String,
        timestamp: TimeInterval,
        time: TimeInterval,
        hostname: String,
        isFailure: Bool,
        failures: [JunitTestCaseFailure]
    ) {
        self.className = className
        self.name = name
        self.timestamp = timestamp
        self.time = time
        self.hostname = hostname
        self.isFailure = isFailure
        self.failures = failures
    }
}

public final class JunitGenerator {
    private let testCases: [JunitTestCase]
    private let iso8601DateFormatter = ISO8601DateFormatter()
    
    public init(testCases: [JunitTestCase], timeZone: TimeZone = TimeZone.autoupdatingCurrent) {
        self.testCases = testCases
        iso8601DateFormatter.timeZone = timeZone
    }
    
    public func writeReport(path: String) throws {
        let report = try generateReport()
        try report.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    func generateReport() throws -> String {
        var classNameToTestCases = [String: [JunitTestCase]]()
        var totalTestCount: Int = 0
        var totalFailureCount: Int = 0
        testCases.forEach { (testCase: JunitTestCase) in
            let className = testCase.className
            totalTestCount += 1
            if testCase.isFailure {
                totalFailureCount += 1
            }
            if var cases = classNameToTestCases[className] {
                cases.append(testCase)
                classNameToTestCases[className] = cases
            } else {
                classNameToTestCases[className] = [testCase]
            }
        }
        
        let xmlTestSuites = XMLElement(name: "testsuites")
        try xmlTestSuites.addAttribute(withName: "name", stringValue: "xctest")
        try xmlTestSuites.addAttribute(withName: "tests", stringValue: "\(totalTestCount)")
        try xmlTestSuites.addAttribute(withName: "failures", stringValue: "\(totalFailureCount)")
        
        try classNameToTestCases.forEach { (className: String, testCases: [JunitTestCase]) in
            var testSuiteTestCount: Int = 0
            var testSuiteFailureCount: Int = 0
            
            let xmlTestSuite = XMLElement(name: "testsuite")
            try xmlTestSuite.addAttribute(withName: "name", stringValue: "\(className)")
            
            try testCases.forEach { (testCase: JunitTestCase) in
                let xmlTestCase = XMLElement(name: "testcase")
                
                testSuiteTestCount += 1
                if testCase.isFailure {
                    testSuiteFailureCount += 1
                    try testCase.failures.forEach { failure in
                        let xmlFailure = XMLElement(name: "failure", stringValue: "\(failure.fileLine)")
                        let message = failure.reason.components(separatedBy: CharacterSet.controlCharacters).joined(separator: "")
                        try xmlFailure.addAttribute(withName: "message", stringValue: "\(message)")
                        xmlTestCase.addChild(xmlFailure)
                    }
                }
                
                try xmlTestCase.addAttribute(withName: "classname", stringValue: "\(className)")
                try xmlTestCase.addAttribute(withName: "name", stringValue: "\(testCase.name)")
                try xmlTestCase.addAttribute(withName: "timestamp", stringValue: "\(iso8601DateFormatter.string(from: Date(timeIntervalSince1970: testCase.timestamp)))")
                try xmlTestCase.addAttribute(withName: "time", stringValue: "\(testCase.time)")
                try xmlTestCase.addAttribute(withName: "hostname", stringValue: "\(testCase.hostname)")
                xmlTestSuite.addChild(xmlTestCase)
            }
            
            try xmlTestSuite.addAttribute(withName: "tests", stringValue: "\(testSuiteTestCount)")
            try xmlTestSuite.addAttribute(withName: "failures", stringValue: "\(testSuiteFailureCount)")
            xmlTestSuites.addChild(xmlTestSuite)
        }
        
        let xml = XMLDocument()
        xml.setRootElement(xmlTestSuites)
        xml.version = "1.0"
        xml.characterEncoding = "UTF-8"
        return xml.xmlString(options: [.nodePrettyPrint]) + "\n"
    }
}

public enum JunitAttributeError: Error {
    case failedToAddAttribute(name: String, value: String)
}

extension XMLElement {
    func addAttribute(withName name: String, stringValue: String) throws {
        guard let attribute = XMLNode.attribute(withName: name, stringValue: stringValue) as? XMLNode else {
            throw JunitAttributeError.failedToAddAttribute(name: name, value: stringValue)
        }
        self.addAttribute(attribute)
    }
}
