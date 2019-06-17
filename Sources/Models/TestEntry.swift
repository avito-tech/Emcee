import Foundation

/**
 * Represents a single existing test.
 * Think about TestEntry as a "resolved" TestToRun with all information filled and validated in runtime.
 */
public final class TestEntry: CustomStringConvertible, Codable, Hashable {
    /// TestClassName/testMethodName.
    public let testName: TestName

    /// Tags assigned to this test entry.
    public let tags: [String]
    
    /** Test case id in test reporting system. */
    public let caseId: UInt?
    
    public init(testName: TestName, tags: [String], caseId: UInt?) {
        self.testName = testName
        self.tags = tags
        self.caseId = caseId
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
        hasher.combine(testName)
        hasher.combine(tags)
        hasher.combine(caseId)
    }
    
    public static func == (left: TestEntry, right: TestEntry) -> Bool {
        return left.testName == right.testName
            && left.tags == right.tags
            && left.caseId == right.caseId
    }
}
