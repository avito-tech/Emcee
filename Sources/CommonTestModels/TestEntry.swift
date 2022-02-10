import Foundation

/**
 * Represents a single existing test.
 * Think about TestEntry as a "resolved" TestToRun with all information filled and validated in runtime.
 */
public struct TestEntry: CustomStringConvertible, Codable, Hashable {
    public let testName: TestName
    public let tags: [String]
    public let caseId: UInt?
    
    public init(testName: TestName, tags: [String], caseId: UInt?) {
        self.testName = testName
        self.tags = tags
        self.caseId = caseId
    }
    
    public var description: String {
        var components = [String]()
        
        components.append("\(testName)")
        if let caseId = caseId {
            components.append("case id: \(caseId)")
        }

        if !tags.isEmpty {
            components.append("tags: \(tags)")
        }
        
        let componentsJoined = components.joined(separator: ", ")
        
        return "<\(componentsJoined)>"
    }
}
