import Foundation

public struct TestException: Codable, CustomStringConvertible, Equatable {
    public let reason: String
    public let filePathInProject: String
    public let lineNumber: Int32
    public let relatedTestName: TestName?
    
    public init(reason: String, filePathInProject: String, lineNumber: Int32, relatedTestName: TestName?) {
        self.reason = reason
        self.filePathInProject = filePathInProject
        self.lineNumber = lineNumber
        self.relatedTestName = relatedTestName
    }
    
    public var description: String {
        var result = [String]()
        if let relatedTestName = relatedTestName {
            result.append(relatedTestName.stringValue)
        }
        result.append("\(filePathInProject):\(lineNumber): \(reason)")
        return result.joined(separator: " ")
    }
}
