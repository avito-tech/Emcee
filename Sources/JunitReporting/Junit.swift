import Foundation

public struct JunitTestCaseFailure {
    public let reason: String        // "Test failed because of blah"
    public let fileLine: String      // File.swift:42

    public init(reason: String, fileLine: String) {
        self.reason = reason
        self.fileLine = fileLine
    }
}

public struct JunitTestCaseBoundaries {
    public let processId: Int32
    public let simulatorId: String
    public let startTime: TimeInterval
    public let finishTime: TimeInterval

    public init(processId: Int32, simulatorId: String, startTime: TimeInterval, finishTime: TimeInterval) {
        self.processId = processId
        self.simulatorId = simulatorId
        self.startTime = startTime
        self.finishTime = finishTime
    }
}

public struct JunitTestCase {
    public let className: String     /* FunctionalTests.AbuseTests_91953 */
    public let name: String          /* test, testDataSet0 */
    public let time: TimeInterval    /* 34.56 */
    public let isFailure: Bool
    public let failures: [JunitTestCaseFailure]
    public let boundaries: JunitTestCaseBoundaries

    public init(
        className: String,
        name: String,
        time: TimeInterval,
        isFailure: Bool,
        failures: [JunitTestCaseFailure],
        boundaries: JunitTestCaseBoundaries
        )
    {
        self.className = className
        self.name = name
        self.time = time
        self.isFailure = isFailure
        self.failures = failures
        self.boundaries = boundaries
    }
}

public final class JunitGenerator {
    private let testCases: [JunitTestCase]
    
    public init(testCases: [JunitTestCase]) {
        self.testCases = testCases
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
                try xmlTestCase.addAttribute(withName: "time", stringValue: "\(testCase.time)")
                try xmlTestCase.addAttribute(withName: "processId", stringValue: "\(testCase.boundaries.processId)")
                try xmlTestCase.addAttribute(withName: "simulatorId", stringValue: "\(testCase.boundaries.simulatorId)")
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
