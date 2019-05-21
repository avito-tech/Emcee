import Foundation

/**
 * Represents a single existing test.
 * Think about TestEntry as a "resolved" TestToRun with all information filled and validated in runtime.
 */
public final class TestEntry: CustomStringConvertible, Codable, Hashable {
    /** TestClassName/testMethodName */
    public let testName: String
    
    /** Test class name, e.g. MainPageTests */
    public let className: String
    
    /** Test method name, e.g.: testMainPageHasLoginButton, test, testDataSource0 etc. */
    public let methodName: String

    /// Tags assigned to this test entry.
    public let tags: [String]
    
    /** Test case id in test reporting system. */
    public let caseId: UInt?
    
    public init(className: String, methodName: String, tags: [String], caseId: UInt?) {
        self.testName = className + "/" + methodName
        self.className = className
        self.methodName = methodName
        self.tags = tags
        self.caseId = caseId
    }

    // TODO MBS-4934: remove, left for backwards compatibility
    public convenience init(className: String, methodName: String, caseId: UInt?) {
        self.init(className: className, methodName: methodName, tags: [], caseId: caseId)
    }
    
    public var description: String {
        var components = [String]()
        
        components.append("'\(testName)'")
        if let caseId = caseId {
            components.append("case id: \(caseId)")
        }

        components.append("tags: \(tags)")
        
        let componentsJoined = components.joined(separator: ", ")
        
        return "<\(TestEntry.self) \(componentsJoined)>"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(className)
        hasher.combine(methodName)
        hasher.combine(tags)
        hasher.combine(caseId)
    }
    
    public static func == (left: TestEntry, right: TestEntry) -> Bool {
        return left.testName == right.testName
            && left.tags == right.tags
            && left.caseId == right.caseId
    }
}
