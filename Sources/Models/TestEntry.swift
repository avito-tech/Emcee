import Foundation

/**
 * Represents a single existing test.
 * Think about TestEntry as a "resolved" TestToRun with all information filled and validated in runtime.
 */
public struct TestEntry: CustomStringConvertible, Codable, Hashable {
    /** TestClassName/testMethodName */
    public let testName: String
    
    /** Test class name, e.g. MainPageTests */
    public let className: String
    
    /** Test method name, e.g.: testMainPageHasLoginButton, test, testDataSource0 etc. */
    public let methodName: String
    
    /** Test case id in test reporting system. */
    public let caseId: UInt?
    
    public init(className: String, methodName: String, caseId: UInt?) {
        self.testName = className + "/" + methodName
        self.className = className
        self.methodName = methodName
        self.caseId = caseId
    }
    
    public var description: String {
        var components = [String]()
        
        components.append("'\(testName)'")
        if let caseId = caseId {
            components.append("case id: \(caseId)")
        }
        
        let componentsJoined = components.joined(separator: ", ")
        
        return "(\(TestEntry.self) \(componentsJoined))"
    }
    
    public var hashValue: Int {
        return testName.hashValue
    }
}
